import Entities
import DependenciesMacros

@DependencyClient
public struct SimulatorClient: Sendable {
  public var requestDevices: @Sendable () async throws -> Devices
  public var bootDevice: @Sendable (_ udid: String) throws -> Void
  public var shutdownDevice: @Sendable (_ udid: String) throws -> Void
  public var startLogging: @Sendable (_ udid: String) async throws -> AsyncStream<String>
  public var stopLogging: @Sendable () async -> Void
}

extension SimulatorClient {
  public struct Devices: Equatable, Sendable {
    public let bootedDevices: [SimulatorDevice]
    public let shutdownGroups: [DeviceGroup]
    
    public init(
      bootedDevices: [SimulatorDevice],
      shutdownGroups: [DeviceGroup]
    ) {
      self.bootedDevices = bootedDevices
      self.shutdownGroups = shutdownGroups
    }
  }
}
