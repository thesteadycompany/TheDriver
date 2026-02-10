import Entities
import DependenciesMacros

@DependencyClient
public struct SimulatorClient: Sendable {
  public var requestDevices: @Sendable () async throws -> Devices
  public var bootDevice: @Sendable (_ udid: String) throws -> Void
  public var shutdownDevice: @Sendable (_ udid: String) throws -> Void
  public var installApp: @Sendable (_ udid: String, _ appPath: String) async throws -> Void
  public var launchApp: @Sendable (_ udid: String, _ bundleId: String, _ arguments: [String], _ options: LaunchOptions) async throws -> String
  public var startLogging: @Sendable (_ udid: String, _ predicate: String?) async throws -> AsyncThrowingStream<String, Error>
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

extension SimulatorClient {
  public struct LaunchOptions: Equatable, Sendable {
    public var waitForDebugger: Bool
    public var console: Bool
    public var stdoutPath: String?
    public var stderrPath: String?
    public var terminateRunningProcess: Bool

    public init(
      waitForDebugger: Bool = false,
      console: Bool = false,
      stdoutPath: String? = nil,
      stderrPath: String? = nil,
      terminateRunningProcess: Bool = false
    ) {
      self.waitForDebugger = waitForDebugger
      self.console = console
      self.stdoutPath = stdoutPath
      self.stderrPath = stderrPath
      self.terminateRunningProcess = terminateRunningProcess
    }
  }
}
