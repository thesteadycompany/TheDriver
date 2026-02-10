import FeatureCore
import Foundation
import MainTab
import Onboarding

@Reducer
public struct AppFeature {
  @ObservableState
  public struct State: Equatable {
    var mainTab: MainTabFeature.State = .init()
    var onboarding: OnboardingFeature.State = .init()
    var isOnboardingPresented = true
    
    public init() {}
  }
  
  @CasePathable
  public enum Action: BindableAction {
    case binding(BindingAction<State>)
    case child(Child)
    
    @CasePathable
    public enum Child {
      case mainTab(MainTabFeature.Action)
      case onboarding(OnboardingFeature.Action)
    }
  }
  
  public init() {}
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    Scope(state: \.mainTab, action: \.child.mainTab) {
      MainTabFeature()
    }
    Scope(state: \.onboarding, action: \.child.onboarding) {
      OnboardingFeature()
    }
    Reduce { state, action in
      switch action {
      case .binding:
        return .none
      case let .child(action):
        return child(&state, action)
      }
    }
  }
  
  private func child(_ state: inout State, _ action: Action.Child) -> Effect<Action> {
    switch action {
    case .mainTab:
      return .none
    case let .onboarding(action):
      return onboarding(&state, action)
    }
  }

  private func onboarding(
    _ state: inout State,
    _ action: OnboardingFeature.Action
  ) -> Effect<Action> {
    switch action {
    case let .delegate(.environmentReadinessChanged(isReady)):
      state.isOnboardingPresented = isReady == false
      return .none
    case .local, .view:
      return .none
    }
  }
}
