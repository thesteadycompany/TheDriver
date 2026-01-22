import Entities
import DependenciesMacros

@DependencyClient
public struct SimulatorClient: Sendable {
  public var requestDevices: @Sendable () async throws -> [SimulatorDevice]
}
