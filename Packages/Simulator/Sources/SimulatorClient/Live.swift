import Dependencies
import Entities
import Foundation

extension SimulatorClient: DependencyKey {
  public static let liveValue = SimulatorClient(
    requestDevices: {
      let path = "/usr/bin/xcrun"
      let process = Process()
      process.executableURL = .init(fileURLWithPath: path)
      process.arguments = ["simctl", "list", "devices", "--json"]
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
      let data = Data(stdOut.utf8)
      var bootedDevices: [SimulatorDevice] = []
      var shutdownDevices: [SimulatorDevice] = []
      
      try JSONDecoder()
        .decode(DevicesResponse.self, from: data)
        .toEntities()
        .sorted(by: { $0.name > $1.name })
        .forEach {
          if $0.state.isBooted {
            bootedDevices.append($0)
          } else {
            shutdownDevices.append($0)
          }
        }
      return bootedDevices + shutdownDevices
    }
  )
}
