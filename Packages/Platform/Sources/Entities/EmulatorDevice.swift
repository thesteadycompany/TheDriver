import Foundation

public struct EmulatorDevice: Equatable, Identifiable, Sendable {
  public var id: String { serial }
  public let serial: String
  public let name: String
  public let avdName: String
  public let state: DeviceState
  public let apiLevel: Int?
  public var displayName: String {
    avdName.replacingOccurrences(of: "_", with: " ")
  }

  public init(
    serial: String,
    name: String,
    avdName: String? = nil,
    state: DeviceState,
    apiLevel: Int? = nil
  ) {
    self.serial = serial
    self.name = name
    self.avdName = avdName ?? name
    self.state = state
    self.apiLevel = apiLevel
  }
}
