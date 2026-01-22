import Foundation

public enum DeviceState: String, Equatable, Sendable, Hashable {
  case booted = "Booted"
  case shutdown = "Shutdown"
}
