import Foundation

public struct DeviceGroup: Equatable, Identifiable, Sendable {
  public var id: String { os }
  public let os: String
  public var devices: [SimulatorDevice]
  
  public init(
    os: String,
    devices: [SimulatorDevice]
  ) {
    self.os = os
    self.devices = devices
  }
  
  public init(
    device: SimulatorDevice
  ) {
    self.os = device.os
    self.devices = [device]
  }
  
  public mutating func append(_ device: SimulatorDevice) {
    devices.append(device)
  }
}
