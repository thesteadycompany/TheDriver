import Dependencies
import Entities
import Foundation

extension EmulatorClient: DependencyKey {
  public static let liveValue = EmulatorClient(
    requestDevices: {
      let output = try EmulatorRunner.shared.run(.listDevices)
      let parser = ADBDevicesParser()
      let devices = parser.parse(output)

      let booted = devices.filter(\.state.isBooted)
      let shutdown = devices.filter { $0.state.isBooted == false }

      return .init(
        bootedDevices: booted,
        shutdownDevices: shutdown
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
    }
  )
}

struct EmulatorRunner: Sendable {
  let path = "/usr/bin/env"

  static let shared = EmulatorRunner()

  @discardableResult
  func run(_ command: EmulatorCommand) throws -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: path)
    process.arguments = command.arguments

    let outPipe = Pipe()
    let errorPipe = Pipe()
    process.standardOutput = outPipe
    process.standardError = errorPipe

    do {
      try process.run()
    } catch {
      throw EmulatorError.notFound(path: path)
    }

    process.waitUntilExit()

    let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
    let stdOut = String(data: outData, encoding: .utf8) ?? ""
    let stdError = String(data: errorData, encoding: .utf8) ?? ""

    if process.terminationStatus != 0 {
      throw EmulatorError.nonZeroExit(code: process.terminationStatus, description: stdError)
    }

    return stdOut
  }

  @discardableResult
  func runAsync(_ command: EmulatorCommand) async throws -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: path)
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
            throwing: EmulatorError.nonZeroExit(code: process.terminationStatus, description: stdError)
          )
        } else {
          continuation.resume(returning: stdOut)
        }
      }

      do {
        try process.run()
      } catch {
        continuation.resume(throwing: EmulatorError.notFound(path: path))
      }
    }
  }
}
