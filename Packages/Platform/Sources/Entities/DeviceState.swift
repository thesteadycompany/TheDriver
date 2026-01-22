import Foundation

public enum DeviceState: String, Equatable, Sendable, Hashable {
  case booted = "Booted"
  case shutdown = "Shutdown"
}

extension DeviceState {
  public var isBooted: Bool {
    self == .booted
  }
}
