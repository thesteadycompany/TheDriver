import Foundation

public struct RunningApp: Equatable, Sendable {
  public let bundleId: String
  public let displayName: String
  public let deviceId: String
  
  public init(
    bundleId: String,
    displayName: String,
    deviceId: String
  ) {
    self.bundleId = bundleId
    self.displayName = displayName
    self.deviceId = deviceId
  }
}
