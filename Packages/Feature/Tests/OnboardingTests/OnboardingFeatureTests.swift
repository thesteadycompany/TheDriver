import DeveloperToolsClient
import FeatureCore
import XCTest

@testable import Onboarding

@MainActor
final class OnboardingFeatureTests: XCTestCase {
  func testOnAppearLoadsEnvironmentStatus() async {
    let status = DeveloperToolsClient.EnvironmentStatus(
      isXcodeInstalled: true,
      isSimulatorAppAvailable: true,
      isSimctlAvailable: true
    )

    let store = TestStore(initialState: .init()) {
      OnboardingFeature().body
    } withDependencies: {
      $0[DeveloperToolsClient.self].checkEnvironment = { status }
    }

    await store.send(.view(.onAppear)) {
      $0.isChecking = true
    }

    await store.receive(.local(.environmentStatusLoaded(status))) {
      $0.environmentStatus = status
      $0.isChecking = false
    }
    await store.receive(.delegate(.environmentReadinessChanged(true)))
  }

  func testInstallTappedStreamsLogsAndRechecks() async {
    let checker = EnvironmentChecker(
      statuses: [
        .init(isXcodeInstalled: true, isSimulatorAppAvailable: false, isSimctlAvailable: false),
        .init(isXcodeInstalled: true, isSimulatorAppAvailable: true, isSimctlAvailable: true),
      ]
    )

    var state = OnboardingFeature.State()
    state.environmentStatus = .init(
      isXcodeInstalled: true,
      isSimulatorAppAvailable: false,
      isSimctlAvailable: false
    )

    let store = TestStore(initialState: state) {
      OnboardingFeature().body
    } withDependencies: {
      $0[DeveloperToolsClient.self].checkEnvironment = {
        await checker.next()
      }
      $0[DeveloperToolsClient.self].installIOSPlatform = {
        AsyncThrowingStream { continuation in
          continuation.yield("[stdout] downloading")
          continuation.yield("[stderr] validating")
          continuation.finish()
        }
      }
    }

    await store.send(.view(.installTapped)) {
      $0.isInstalling = true
      $0.installErrorMessage = nil
      $0.installLogs = []
    }

    await store.receive(.local(.installLogReceived("[stdout] downloading"))) {
      $0.installLogs = ["[stdout] downloading"]
    }

    await store.receive(.local(.installLogReceived("[stderr] validating"))) {
      $0.installLogs = ["[stdout] downloading", "[stderr] validating"]
    }

    await store.receive(.local(.installSucceeded)) {
      $0.isInstalling = false
      $0.installErrorMessage = nil
      $0.installLogs = ["[stdout] downloading", "[stderr] validating", "[완료] iOS 플랫폼 설치가 완료되었습니다."]
    }

    await store.receive(.view(.recheckTapped)) {
      $0.isChecking = true
    }

    let readyStatus = DeveloperToolsClient.EnvironmentStatus(
      isXcodeInstalled: true,
      isSimulatorAppAvailable: true,
      isSimctlAvailable: true
    )

    await store.receive(.local(.environmentStatusLoaded(readyStatus))) {
      $0.environmentStatus = readyStatus
      $0.isChecking = false
    }
    await store.receive(.delegate(.environmentReadinessChanged(true)))
  }

  func testInstallTappedFailureAddsErrorLog() async {
    var state = OnboardingFeature.State()
    state.environmentStatus = .init(
      isXcodeInstalled: true,
      isSimulatorAppAvailable: false,
      isSimctlAvailable: false
    )

    let store = TestStore(initialState: state) {
      OnboardingFeature().body
    } withDependencies: {
      $0[DeveloperToolsClient.self].installIOSPlatform = {
        AsyncThrowingStream { continuation in
          continuation.finish(
            throwing: DeveloperToolsError.nonZeroExit(code: 1, description: "download failed")
          )
        }
      }
    }

    await store.send(.view(.installTapped)) {
      $0.isInstalling = true
      $0.installErrorMessage = nil
      $0.installLogs = []
    }

    await store.receive(.local(.installFailed("설치 명령이 실패했습니다. 종료 코드: 1, download failed"))) {
      $0.isInstalling = false
      $0.installErrorMessage = "설치 명령이 실패했습니다. 종료 코드: 1, download failed"
      $0.installLogs = ["[오류] 설치 명령이 실패했습니다. 종료 코드: 1, download failed"]
    }
    await store.receive(.delegate(.environmentReadinessChanged(false)))
  }
}

private actor EnvironmentChecker {
  private var statuses: [DeveloperToolsClient.EnvironmentStatus]

  init(statuses: [DeveloperToolsClient.EnvironmentStatus]) {
    self.statuses = statuses
  }

  func next() -> DeveloperToolsClient.EnvironmentStatus {
    if statuses.count > 1 {
      return statuses.removeFirst()
    }
    return statuses.first ?? .init(
      isXcodeInstalled: false,
      isSimulatorAppAvailable: false,
      isSimctlAvailable: false
    )
  }
}
