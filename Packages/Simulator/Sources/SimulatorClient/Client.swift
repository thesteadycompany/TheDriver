import Entities
import DependenciesMacros

@DependencyClient
public struct SimulatorClient: Sendable {
  public var requestDevices: @Sendable () async throws -> [SimulatorDevice]
  public var bootDevice: @Sendable (_ udid: String) throws -> Void
  public var shutdownDevice: @Sendable (_ udid: String) throws -> Void
}
