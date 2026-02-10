import Foundation

public struct EmulatorDevice: Equatable, Identifiable, Sendable {
  public var id: String { serial }
  public let serial: String
  public let name: String
  public let state: DeviceState
  public let apiLevel: Int?

  public init(
    serial: String,
    name: String,
    state: DeviceState,
    apiLevel: Int? = nil
  ) {
    self.serial = serial
    self.name = name
    self.state = state
    self.apiLevel = apiLevel
  }
}
