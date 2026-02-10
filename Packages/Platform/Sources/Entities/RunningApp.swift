import Foundation

public struct RunningApp: Equatable, Sendable {
  public let bundleId: String
  public let processName: String
  public let displayName: String
  public let deviceId: String
  
  public init(
    bundleId: String,
    processName: String,
    displayName: String,
    deviceId: String
  ) {
    self.bundleId = bundleId
    self.processName = processName
    self.displayName = displayName
    self.deviceId = deviceId
  }
}
