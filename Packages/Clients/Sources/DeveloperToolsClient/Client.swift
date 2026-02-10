import DependenciesMacros

@DependencyClient
public struct DeveloperToolsClient: Sendable {
  public var checkEnvironment: @Sendable () async -> EnvironmentStatus = {
    .init(
      isXcodeInstalled: false,
      isSimulatorAppAvailable: false,
      isSimctlAvailable: false
    )
  }
  public var installIOSPlatform: @Sendable () async throws -> AsyncThrowingStream<String, Error> = {
    .init { continuation in
      continuation.finish()
    }
  }
  public var cancelInstall: @Sendable () async -> Void = {}
  public var openXcodeInstallPage: @Sendable () async throws -> Void = {}
}

extension DeveloperToolsClient {
  public struct EnvironmentStatus: Equatable, Sendable {
    public let isXcodeInstalled: Bool
    public let isSimulatorAppAvailable: Bool
    public let isSimctlAvailable: Bool

    public var isReady: Bool {
      isXcodeInstalled && isSimulatorAppAvailable && isSimctlAvailable
    }

    public var detailMessage: String {
      if isReady {
        return "개발 환경이 준비되었습니다."
      }
      if isXcodeInstalled == false {
        return "Xcode 설치가 필요합니다."
      }
      if isSimulatorAppAvailable == false {
        return "Simulator 앱이 확인되지 않았습니다."
      }
      return "simctl 명령이 동작하지 않습니다."
    }

    public init(
      isXcodeInstalled: Bool,
      isSimulatorAppAvailable: Bool,
      isSimctlAvailable: Bool
    ) {
      self.isXcodeInstalled = isXcodeInstalled
      self.isSimulatorAppAvailable = isSimulatorAppAvailable
      self.isSimctlAvailable = isSimctlAvailable
    }
  }
}
