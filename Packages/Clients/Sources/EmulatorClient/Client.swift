import DependenciesMacros
import Entities

@DependencyClient
public struct EmulatorClient: Sendable {
  public var requestDevices: @Sendable () async throws -> Devices = {
    .init(bootedDevices: [], shutdownDevices: [])
  }
  public var bootDevice: @Sendable (_ avdName: String) async throws -> Void = { _ in }
  public var shutdownDevice: @Sendable (_ serial: String) async throws -> Void = { _ in }
  public var installAPK: @Sendable (_ serial: String, _ apkPath: String) async throws -> Void = { _, _ in }
  public var launchApp: @Sendable (_ serial: String, _ packageName: String) async throws -> Void = { _, _ in }
}

extension EmulatorClient {
  public struct Devices: Equatable, Sendable {
    public let bootedDevices: [EmulatorDevice]
    public let shutdownDevices: [EmulatorDevice]

    public init(
      bootedDevices: [EmulatorDevice],
      shutdownDevices: [EmulatorDevice]
    ) {
      self.bootedDevices = bootedDevices
      self.shutdownDevices = shutdownDevices
    }
  }
}
