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
