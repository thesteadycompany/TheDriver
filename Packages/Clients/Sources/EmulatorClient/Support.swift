import Entities
import Foundation

struct ADBDevicesParser {
  func parse(_ output: String) -> [EmulatorDevice] {
    output
      .split(separator: "\n", omittingEmptySubsequences: true)
      .dropFirst()
      .compactMap { line in
        let parts = line
          .split(whereSeparator: \.isWhitespace)
          .map(String.init)
        guard parts.count >= 2 else { return nil }

        let serial = parts[0]
        let stateToken = parts[1]

        let modelToken = parts.first(where: { $0.hasPrefix("model:") })
        let name = modelToken?
          .replacingOccurrences(of: "model:", with: "")
          .replacingOccurrences(of: "_", with: " ") ?? serial

        let apiLevelToken = parts.first(where: { $0.hasPrefix("sdk:") })
        let apiLevel = apiLevelToken
          .flatMap { $0.replacingOccurrences(of: "sdk:", with: "") }
          .flatMap(Int.init)

        return .init(
          serial: serial,
          name: name,
          state: mapState(stateToken),
          apiLevel: apiLevel
        )
      }
  }

  private func mapState(_ token: String) -> DeviceState {
    token == "device" ? .booted : .shutdown
  }
}
