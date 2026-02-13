import Dependencies
import Entities
import Foundation

extension SimulatorClient: DependencyKey {
  public static let liveValue = SimulatorClient(
    requestDevices: {
      let stdOut = try Runner.shared.run(.listDevices)
      let data = Data(stdOut.utf8)
      var bootedDevices: [SimulatorDevice] = []
      var shutdownGroups: [DeviceGroup] = []
      
      try JSONDecoder()
        .decode(DevicesResponse.self, from: data)
        .toEntities()
        .sorted(by: { $0.name > $1.name })
        .sorted(by: { $0.os > $1.os })
        .forEach { device in
          if device.state.isBooted {
            bootedDevices.append(device)
          } else {
            if let index = shutdownGroups.firstIndex(where: { $0.os == device.os }) {
              shutdownGroups[index].append(device)
            } else {
              shutdownGroups.append(.init(device: device))
            }
          }
        }
      return .init(
        bootedDevices: bootedDevices,
        shutdownGroups: shutdownGroups
      )
    },
    bootDevice: { udid in
      try Runner.shared.run(.boot(udid: udid))
    },
    shutdownDevice: { udid in
      try Runner.shared.run(.shutdown(udid: udid))
    },
    installApp: { udid, appPath in
      _ = try await Runner.shared.runAsync(.bootStatus(udid: udid))
      _ = try await Runner.shared.runAsync(.install(udid: udid, appPath: appPath))
    },
    launchApp: { udid, bundleId, arguments, options in
      if options.console, (options.stdoutPath != nil || options.stderrPath != nil) {
        throw SimulatorError.invalidArguments(description: "--console cannot be combined with --stdout/--stderr")
      }
      _ = try await Runner.shared.runAsync(.bootStatus(udid: udid))
      return try await Runner.shared.runAsync(
        .launch(udid: udid, bundleId: bundleId, arguments: arguments, options: options)
      )
    },
    startLogging: { udid, predicate in
      try await LogStreamer.shared.start(udid: udid, predicate: predicate)
    },
    stopLogging: {
      await LogStreamer.shared.stop()
    }
  )
}

struct Runner: Sendable {
  let path = "/usr/bin/xcrun"
  
  static let shared = Runner()
  
  @discardableResult
  func run(_ command: SimctlCommand) throws -> String {
    let process = Process()
    process.executableURL = .init(fileURLWithPath: path)
    process.arguments = command.arguments
    let outPipe = Pipe()
    let errorPipe = Pipe()
    process.standardOutput = outPipe
    process.standardError = errorPipe
    do {
      try process.run()
    } catch {
      throw SimulatorError.notFound(path: path)
    }
    process.waitUntilExit()
    let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
    let stdOut = String(data: outData, encoding: .utf8) ?? ""
    let stdError = String(data: errorData, encoding: .utf8) ?? ""
    if process.terminationStatus != 0 {
      throw SimulatorError.nonZeroExit(code: process.terminationStatus, description: stdError)
    }
    return stdOut
  }

  @discardableResult
  func runAsync(_ command: SimctlCommand) async throws -> String {
    let process = Process()
    process.executableURL = .init(fileURLWithPath: path)
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
          continuation.resume(
            throwing: SimulatorError.nonZeroExit(code: process.terminationStatus, description: stdError)
          )
        } else {
          continuation.resume(returning: stdOut)
        }
      }

      do {
        try process.run()
      } catch {
        continuation.resume(throwing: SimulatorError.notFound(path: path))
      }
    }
  }
}

@globalActor
final actor LogStreamer {
  static let shared = LogStreamer()
  
  private var process: Process?
  private var outPipe: Pipe?
  private var errPipe: Pipe?
  
  func start(udid: String, predicate: String?) throws -> AsyncThrowingStream<String, Error> {
    stop()
    let path = Runner.shared.path
    let process = Process()
    process.executableURL = .init(fileURLWithPath: path)
    var arguments = [
      "simctl", "spawn", udid,
      "log", "stream",
      "--style", "compact",
      "--level", "debug"
    ]
    if let predicate {
      arguments.append(contentsOf: ["--predicate", predicate])
    }
    process.arguments = arguments
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
        chunk.split(separator: "\n", omittingEmptySubsequences: true)
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
          throwing: SimulatorError.nonZeroExit(
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
        continuation.finish(throwing: SimulatorError.notFound(path: path))
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
