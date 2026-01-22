import Foundation

public struct SimulatorDevice: Equatable, Identifiable, Sendable {
  public var id: String { udid }
  public let udid: String
  public let name: String
  public let state: DeviceState
  public let isAvailable: Bool
  
  public init(
    udid: String,
    name: String,
    state: DeviceState,
    isAvailable: Bool
  ) {
    self.udid = udid
    self.name = name
    self.state = state
    self.isAvailable = isAvailable
  }
}
