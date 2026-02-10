import DeveloperToolsClient
import FeatureCore
import Foundation

@Reducer
public struct OnboardingFeature {
  @ObservableState
  public struct State: Equatable {
    var environmentStatus: DeveloperToolsClient.EnvironmentStatus?
    var installLogs: [String] = []
    var isChecking = false
    var isInstalling = false
    var installErrorMessage: String?

    public var isEnvironmentReady: Bool {
      environmentStatus?.isReady == true
    }

    public init() {}
  }

@CasePathable
  public enum Action: ViewAction {
    case delegate(Delegate)
    case local(Local)
    case view(View)

    @CasePathable
    public enum Delegate {
      case environmentReadinessChanged(Bool)
    }

    @CasePathable
    public enum Local {
      case environmentStatusLoaded(DeveloperToolsClient.EnvironmentStatus)
      case installFailed(String)
      case installSucceeded
      case installLogReceived(String)
    }

    @CasePathable
    public enum View {
      case clearLogsTapped
      case installTapped
      case onAppear
      case recheckTapped
    }
  }

  public init() {}

  private enum CancelID {
    case install
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .delegate:
        return .none
      case let .local(action):
        return local(&state, action)
      case let .view(action):
        return view(&state, action)
      }
    }
  }

  private func local(_ state: inout State, _ action: Action.Local) -> Effect<Action> {
    switch action {
    case let .environmentStatusLoaded(status):
      state.environmentStatus = status
      state.isChecking = false
      return .send(.delegate(.environmentReadinessChanged(status.isReady)))

    case .installSucceeded:
      state.isInstalling = false
      state.installErrorMessage = nil
      state.installLogs.append("[완료] iOS 플랫폼 설치가 완료되었습니다.")
      return .send(.view(.recheckTapped))

    case let .installFailed(message):
      state.isInstalling = false
      state.installErrorMessage = message
      state.installLogs.append("[오류] \(message)")
      return .send(.delegate(.environmentReadinessChanged(false)))

    case let .installLogReceived(log):
      state.installLogs.append(log)
      if state.installLogs.count > 1000 {
        state.installLogs.removeFirst(state.installLogs.count - 1000)
      }
      return .none
    }
  }

  private func view(_ state: inout State, _ action: Action.View) -> Effect<Action> {
    switch action {
    case .clearLogsTapped:
      state.installLogs = []
      return .none

    case .installTapped:
      @Dependency(DeveloperToolsClient.self) var client
      guard state.isInstalling == false else { return .none }

      state.installErrorMessage = nil
      state.installLogs = []

      guard let status = state.environmentStatus else {
        return .send(.view(.recheckTapped))
      }

      if status.isXcodeInstalled == false {
        return .runWithToast { send in
          try await client.openXcodeInstallPage()
          await send(.local(.installLogReceived("[안내] Xcode 설치 페이지를 열었습니다.")))
        }
      }

      state.isInstalling = true
      return .run { send in
        do {
          let stream = try await client.installIOSPlatform()
          for try await line in stream {
            await send(.local(.installLogReceived(line)))
          }
          await send(.local(.installSucceeded))
        } catch {
          await send(.local(.installFailed(Self.errorDescription(error))))
        }
      }
      .cancellable(id: CancelID.install, cancelInFlight: true)

    case .onAppear:
      state.isChecking = true
      return checkEnvironmentEffect()

    case .recheckTapped:
      state.isChecking = true
      return checkEnvironmentEffect()
    }
  }

  private func checkEnvironmentEffect() -> Effect<Action> {
    @Dependency(DeveloperToolsClient.self) var client
    return .run { send in
      let status = await client.checkEnvironment()
      await send(.local(.environmentStatusLoaded(status)))
    }
  }

  private static func errorDescription(_ error: any Error) -> String {
    guard let error = error as? DeveloperToolsError else {
      return error.localizedDescription
    }

    switch error {
    case let .notFound(path):
      return "실행 파일을 찾을 수 없습니다: \(path)"
    case let .nonZeroExit(code, description):
      let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmed.isEmpty {
        return "설치 명령이 실패했습니다. 종료 코드: \(code)"
      }
      return "설치 명령이 실패했습니다. 종료 코드: \(code), \(trimmed)"
    case let .failedToOpenURL(url):
      return "설치 페이지를 열 수 없습니다: \(url)"
    }
  }
}
