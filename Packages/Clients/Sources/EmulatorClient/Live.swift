import Dependencies
import Entities
import Foundation

extension EmulatorClient: DependencyKey {
  public static let liveValue = EmulatorClient(
    requestDevices: {
      _ = try EmulatorRunner.shared.run(.startADBServer)
      let adbOutput = try EmulatorRunner.shared.run(.listDevices)
      let parser = ADBDevicesParser()
      let connectedDevices = parser
        .parse(adbOutput)
        .filter { $0.serial.hasPrefix("emulator-") }
      let namedDevices = resolveAVDNamesIfNeeded(for: connectedDevices)

      let booted = namedDevices.filter(\.state.isBooted)
      let adbShutdown = namedDevices.filter { $0.state.isBooted == false }
      let avdOutput = try? EmulatorRunner.shared.run(.listAVDs)
      let avdNames = AVDListParser().parse(avdOutput ?? "")
      let shutdownByAVD = avdNames
        .filter { name in
          booted.contains(where: { $0.name == name }) == false
        }
        .map { name in
          EmulatorDevice(
            serial: "avd:\(name)",
            name: name,
            state: .shutdown
          )
        }
      let shutdown = mergeShutdownDevices(adbShutdown, shutdownByAVD)

      return .init(
        bootedDevices: booted,
        shutdownDevices: shutdown
      )
    },
    bootDevice: { avdName in
      try EmulatorRunner.shared.runDetached(.bootDevice(avdName: avdName))
    },
    shutdownDevice: { serial in
      _ = try await EmulatorRunner.shared.runAsync(
        .shutdownDevice(serial: serial)
      )
    },
    installAPK: { serial, apkPath in
      _ = try await EmulatorRunner.shared.runAsync(
        .installAPK(serial: serial, apkPath: apkPath)
      )
    },
    launchApp: { serial, packageName in
      _ = try await EmulatorRunner.shared.runAsync(
        .launchApp(serial: serial, packageName: packageName)
      )
    },
    startLogging: { serial, packageName in
      _ = try EmulatorRunner.shared.run(.startADBServer)
      let pidOutput = try EmulatorRunner.shared.run(
        .resolvePID(serial: serial, packageName: packageName)
      )
      guard let pid = parsePrimaryPID(pidOutput) else {
        throw EmulatorError.nonZeroExit(
          code: 1,
          description: "실행 중인 앱 PID를 찾을 수 없습니다: \(packageName)"
        )
      }
      return try await LogcatStreamer.shared.start(
        serial: serial,
        pid: pid
      )
    },
    stopLogging: {
      await LogcatStreamer.shared.stop()
    }
  )
}

private func resolveAVDNamesIfNeeded(
  for devices: [EmulatorDevice]
) -> [EmulatorDevice] {
  devices.map { device in
    guard device.state.isBooted else { return device }
    guard device.serial.hasPrefix("emulator-") else { return device }
    let avdName = try? EmulatorRunner.shared.run(.runningAVDName(serial: device.serial))
      .trimmingCharacters(in: .whitespacesAndNewlines)
    guard let avdName, avdName.isEmpty == false else { return device }
    return .init(
      serial: device.serial,
      name: avdName,
      state: device.state,
      apiLevel: device.apiLevel
    )
  }
}

private func mergeShutdownDevices(
  _ first: [EmulatorDevice],
  _ second: [EmulatorDevice]
) -> [EmulatorDevice] {
  var seenNames = Set<String>()
  return (first + second).filter { device in
    seenNames.insert(device.name).inserted
  }
}

private func parsePrimaryPID(_ output: String) -> String? {
  output
    .split(whereSeparator: \.isWhitespace)
    .map(String.init)
    .first { $0.isEmpty == false }
}

struct EmulatorRunner: Sendable {
  static let shared = EmulatorRunner()

  @discardableResult
  func run(_ command: EmulatorCommand) throws -> String {
    let process = Process()
    process.executableURL = try resolveExecutableURL(for: command.executableName)
    process.arguments = command.arguments

    let outPipe = Pipe()
    let errorPipe = Pipe()
    process.standardOutput = outPipe
    process.standardError = errorPipe

    do {
      try process.run()
    } catch {
      throw EmulatorError.notFound(path: command.executableName)
    }

    process.waitUntilExit()

    let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
    let stdOut = String(data: outData, encoding: .utf8) ?? ""
    let stdError = String(data: errorData, encoding: .utf8) ?? ""

    if process.terminationStatus != 0 {
      if stdError.localizedCaseInsensitiveContains("No such file or directory") {
        throw EmulatorError.notFound(path: command.executableName)
      }
      throw EmulatorError.nonZeroExit(code: process.terminationStatus, description: stdError)
    }

    return stdOut
  }

  @discardableResult
  func runAsync(_ command: EmulatorCommand) async throws -> String {
    let process = Process()
    process.executableURL = try resolveExecutableURL(for: command.executableName)
    process.arguments = command.arguments

    let outPipe = Pipe()
    let errorPipe = Pipe()
    process.standardOutput = outPipe
    process.standardError = errorPipe

    return try await withCheckedThrowingContinuation { continuation in
      process.terminationHandler = { process in
        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let stdOut = String(data: outData, encoding: .utf8) ?? ""
        let stdError = String(data: errorData, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
          if stdError.localizedCaseInsensitiveContains("No such file or directory") {
            continuation.resume(throwing: EmulatorError.notFound(path: command.executableName))
            return
          }
          continuation.resume(
            throwing: EmulatorError.nonZeroExit(code: process.terminationStatus, description: stdError)
          )
        } else {
          continuation.resume(returning: stdOut)
        }
      }

      do {
        try process.run()
      } catch {
        continuation.resume(throwing: EmulatorError.notFound(path: command.executableName))
      }
    }
  }

  func runDetached(_ command: EmulatorCommand) throws {
    let process = Process()
    process.executableURL = try resolveExecutableURL(for: command.executableName)
    process.arguments = command.arguments
    process.standardOutput = Pipe()
    process.standardError = Pipe()
    do {
      try process.run()
    } catch {
      throw EmulatorError.notFound(path: command.executableName)
    }
  }

  fileprivate func resolveExecutableURL(for executableName: String) throws -> URL {
    let fileManager = FileManager.default
    for path in executableSearchPaths(executableName: executableName) {
      if fileManager.isExecutableFile(atPath: path) {
        return URL(fileURLWithPath: path)
      }
    }
    throw EmulatorError.notFound(path: executableName)
  }

  private func executableSearchPaths(executableName: String) -> [String] {
    var paths: [String] = []
    let environment = ProcessInfo.processInfo.environment
    let sdkRoots = [
      environment["ANDROID_SDK_ROOT"],
      environment["ANDROID_HOME"],
      NSHomeDirectory().appending("/Library/Android/sdk"),
    ]
    .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
    .filter { $0.isEmpty == false }

    for sdkRoot in sdkRoots {
      switch executableName {
      case "adb":
        paths.append((sdkRoot as NSString).appendingPathComponent("platform-tools/adb"))
      case "emulator":
        paths.append((sdkRoot as NSString).appendingPathComponent("emulator/emulator"))
      default:
        break
      }
    }

    let pathVariable = environment["PATH"] ?? ""
    for directory in pathVariable.split(separator: ":").map(String.init) {
      paths.append((directory as NSString).appendingPathComponent(executableName))
    }

    var seen = Set<String>()
    return paths.filter { seen.insert($0).inserted }
  }
}

@globalActor
final actor LogcatStreamer {
  static let shared = LogcatStreamer()

  private var process: Process?
  private var outPipe: Pipe?
  private var errPipe: Pipe?

  func start(
    serial: String,
    pid: String
  ) throws -> AsyncThrowingStream<String, Error> {
    stop()
    let executableURL = try EmulatorRunner.shared.resolveExecutableURL(for: "adb")
    let process = Process()
    process.executableURL = executableURL
    process.arguments = EmulatorCommand.streamLogs(serial: serial, pid: pid).arguments
    let outPipe = Pipe()
    let errPipe = Pipe()
    process.standardOutput = outPipe
    process.standardError = errPipe

    let stream = AsyncThrowingStream<String, Error> { continuation in
      let stdError = LockedString()

      outPipe.fileHandleForReading.readabilityHandler = { handle in
        let data = handle.availableData
        if data.isEmpty { return }
        let chunk = String(data: data, encoding: .utf8) ?? ""
        chunk
          .split(separator: "\n", omittingEmptySubsequences: true)
          .forEach { continuation.yield(String($0)) }
      }

      errPipe.fileHandleForReading.readabilityHandler = { handle in
        let data = handle.availableData
        if data.isEmpty { return }
        stdError.append(String(data: data, encoding: .utf8) ?? "")
      }

      process.terminationHandler = { process in
        outPipe.fileHandleForReading.readabilityHandler = nil
        errPipe.fileHandleForReading.readabilityHandler = nil

        if process.terminationStatus == 0 {
          continuation.finish()
          return
        }

        continuation.finish(
          throwing: EmulatorError.nonZeroExit(
            code: process.terminationStatus,
            description: stdError.trimmedValue()
          )
        )
      }

      continuation.onTermination = { _ in
        outPipe.fileHandleForReading.readabilityHandler = nil
        errPipe.fileHandleForReading.readabilityHandler = nil
        process.terminationHandler = nil
        process.terminate()
      }

      do {
        try process.run()
      } catch {
        continuation.finish(throwing: EmulatorError.notFound(path: "adb"))
      }
    }

    self.process = process
    self.outPipe = outPipe
    self.errPipe = errPipe
    return stream
  }

  func stop() {
    outPipe?.fileHandleForReading.readabilityHandler = nil
    errPipe?.fileHandleForReading.readabilityHandler = nil
    process?.terminationHandler = nil
    process?.terminate()
    process = nil
    outPipe = nil
    errPipe = nil
  }
}

private final class LockedString: @unchecked Sendable {
  private let lock = NSLock()
  private var value = ""

  func append(_ text: String) {
    lock.lock()
    value += text
    lock.unlock()
  }

  func trimmedValue() -> String {
    lock.lock()
    let copied = value.trimmingCharacters(in: .whitespacesAndNewlines)
    lock.unlock()
    return copied
  }
}
