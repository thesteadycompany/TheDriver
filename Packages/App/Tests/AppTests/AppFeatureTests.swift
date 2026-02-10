import FeatureCore
import XCTest

@testable import App

@MainActor
final class AppFeatureTests: XCTestCase {
  func testOnboardingVisibilityFollowsDelegateReadiness() async {
    let store = TestStore(initialState: .init()) {
      AppFeature().body
    }

    XCTAssertTrue(store.state.isOnboardingPresented)

    await store.send(.child(.onboarding(.delegate(.environmentReadinessChanged(false))))) {
      $0.isOnboardingPresented = true
    }

    await store.send(.child(.onboarding(.delegate(.environmentReadinessChanged(true))))) {
      $0.isOnboardingPresented = false
    }
  }

  func testMainTabStateStaysIntactWhenOnboardingToggles() async {
    var initialState = AppFeature.State()
    initialState.mainTab.currentTab = .appCenter

    let store = TestStore(initialState: initialState) {
      AppFeature().body
    }

    await store.send(.child(.onboarding(.delegate(.environmentReadinessChanged(false))))) {
      $0.isOnboardingPresented = true
      $0.mainTab.currentTab = .appCenter
    }

    await store.send(.child(.onboarding(.delegate(.environmentReadinessChanged(true))))) {
      $0.isOnboardingPresented = false
      $0.mainTab.currentTab = .appCenter
    }
  }
}
