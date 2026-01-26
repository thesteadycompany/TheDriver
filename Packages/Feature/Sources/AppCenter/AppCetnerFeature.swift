import FeatureCore
import Foundation

@Reducer
public struct AppCenterFeature {
  @ObservableState
  public struct State: Equatable {
    public init() {}
  }
  
  @CasePathable
  public enum Action: ViewAction {
    case view(View)
    
    @CasePathable
    public enum View {
      case uploadTapped
    }
  }
  
  public init() {}
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .view(action):
        return view(&state, action)
      }
    }
  }
  
  private func view(
    _ state: inout State,
    _ action: Action.View
  ) -> Effect<Action> {
    switch action {
    case .uploadTapped:
      return .none
    }
  }
}
