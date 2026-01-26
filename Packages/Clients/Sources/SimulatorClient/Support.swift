import Entities
import Foundation

extension SimulatorClient {
  struct DevicesResponse: Decodable {
    let devices: [String: [DeviceResponse]]
  }
  
  struct DeviceResponse: Decodable {
    let udid: String
    let name: String
    let state: String
    let isAvailable: Bool?
  }
}

extension SimulatorClient.DevicesResponse {
  func toEntities() -> [SimulatorDevice] {
    devices
      .flatMap {
        let os = $0.key
          .split(separator: ".")
          .last?
          .split(separator: "-")
          .joined(separator: ".")
        return $0.value.compactMap { $0.toEntity(with: os ?? "") }
      }
  }
}

extension SimulatorClient.DeviceResponse {
  func toEntity(with os: String) -> SimulatorDevice? {
    guard let state = DeviceState(rawValue: state) else { return nil }
    return .init(
      udid: udid,
      name: name,
      os: os,
      state: state,
      isAvailable: isAvailable ?? false
    )
  }
}
