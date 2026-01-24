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
    startLogging: { udid in
      try await LogStreamer.shared.start(udid: udid)
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
}

@globalActor
final actor LogStreamer {
  static let shared = LogStreamer()
  
  private var process: Process?
  private var outPipe: Pipe?
  
  func start(udid: String) throws -> AsyncStream<String> {
    stop()
    let path = Runner.shared.path
    let process = Process()
    process.executableURL = .init(fileURLWithPath: path)
    process.arguments = [
      "simctl", "spawn", udid,
      "log", "stream",
      "--style", "compact"
      // 필요하면:
      // "--predicate", "subsystem == \"com.yourcompany.yourapp\""
    ]
    let outPipe = Pipe()
    let errPipe = Pipe()
    process.standardOutput = outPipe
    process.standardError = errPipe
    
    let stream = AsyncStream<String> { continuation in
      outPipe.fileHandleForReading.readabilityHandler = { handle in
        let data = handle.availableData
        if data.isEmpty { return }
        let chunk = String(data: data, encoding: .utf8) ?? ""
        chunk.split(separator: "\n", omittingEmptySubsequences: true)
          .forEach { continuation.yield(String($0)) }
      }
      continuation.onTermination = { _ in
        outPipe.fileHandleForReading.readabilityHandler = nil
        process.terminate()
      }
      do {
        try process.run()
      } catch {
        continuation.finish()
      }
    }
    self.process = process
    self.outPipe = outPipe
    return stream
  }
  
  func stop() {
    outPipe?.fileHandleForReading.readabilityHandler = nil
    process?.terminate()
    process = nil
    outPipe = nil
  }
}
