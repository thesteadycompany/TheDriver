import AppKit
import Dependencies
import Foundation

extension DeveloperToolsClient: DependencyKey {
  public static let liveValue = DeveloperToolsClient(
    checkEnvironment: {
      await ToolsEnvironmentChecker().check()
    },
    installIOSPlatform: {
      try await PlatformInstaller.shared.startInstall()
    },
    cancelInstall: {
      await PlatformInstaller.shared.stop()
    },
    openXcodeInstallPage: {
      guard let url = URL(string: "macappstore://itunes.apple.com/app/id497799835") else {
        throw DeveloperToolsError.failedToOpenURL("Xcode")
      }
      let opened = await MainActor.run {
        NSWorkspace.shared.open(url)
      }
      if opened == false {
        throw DeveloperToolsError.failedToOpenURL(url.absoluteString)
      }
    }
  )
}

private struct ToolsEnvironmentChecker {
  func check() async -> DeveloperToolsClient.EnvironmentStatus {
    let fileManager = FileManager.default
    let xcodePath = "/Applications/Xcode.app"
    let simulatorPath = "/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app"

    let isXcodeInstalled = fileManager.fileExists(atPath: xcodePath)
    let isSimulatorAppAvailable = fileManager.fileExists(atPath: simulatorPath)
    let isSimctlAvailable = (try? runProcess(path: "/usr/bin/xcrun", arguments: ["simctl", "help"])) != nil

    return .init(
      isXcodeInstalled: isXcodeInstalled,
      isSimulatorAppAvailable: isSimulatorAppAvailable,
      isSimctlAvailable: isSimctlAvailable
    )
  }

  @discardableResult
  private func runProcess(path: String, arguments: [String]) throws -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: path)
    process.arguments = arguments

    let outPipe = Pipe()
    let errPipe = Pipe()
    process.standardOutput = outPipe
    process.standardError = errPipe

    do {
      try process.run()
    } catch {
      throw DeveloperToolsError.notFound(path: path)
    }

    process.waitUntilExit()

    let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
    let errData = errPipe.fileHandleForReading.readDataToEndOfFile()

    let stdOut = String(data: outData, encoding: .utf8) ?? ""
    let stdErr = String(data: errData, encoding: .utf8) ?? ""

    if process.terminationStatus != 0 {
      throw DeveloperToolsError.nonZeroExit(code: process.terminationStatus, description: stdErr)
    }

    return stdOut
  }
}

@globalActor
private final actor PlatformInstaller {
  static let shared = PlatformInstaller()

  private var process: Process?
  private var outPipe: Pipe?
  private var errPipe: Pipe?

  func startInstall() throws -> AsyncThrowingStream<String, Error> {
    stop()

    let path = "/usr/bin/xcodebuild"
    let process = Process()
    process.executableURL = URL(fileURLWithPath: path)
    process.arguments = ["-downloadPlatform", "iOS"]

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
          .forEach { continuation.yield("[stdout] \($0)") }
      }

      errPipe.fileHandleForReading.readabilityHandler = { handle in
        let data = handle.availableData
        if data.isEmpty { return }
        let chunk = String(data: data, encoding: .utf8) ?? ""
        stdError.append(chunk)
        chunk.split(separator: "\n", omittingEmptySubsequences: true)
          .forEach { continuation.yield("[stderr] \($0)") }
      }

      process.terminationHandler = { process in
        outPipe.fileHandleForReading.readabilityHandler = nil
        errPipe.fileHandleForReading.readabilityHandler = nil

        if process.terminationStatus == 0 {
          continuation.finish()
          return
        }

        continuation.finish(
          throwing: DeveloperToolsError.nonZeroExit(
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
        continuation.finish(throwing: DeveloperToolsError.notFound(path: path))
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
