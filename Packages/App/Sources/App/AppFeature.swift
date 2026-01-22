import FeatureCore
import Foundation
import MainTab

@Reducer
public struct AppFeature {
  @ObservableState
  public struct State: Equatable {
    var mainTab: MainTabFeature.State = .init()
    
    public init() {}
  }
  
  @CasePathable
  public enum Action {
    case mainTab(MainTabFeature.Action)
  }
  
  public init() {}
  
  public var body: some ReducerOf<Self> {
    Scope(state: \.mainTab, action: \.mainTab) {
      MainTabFeature()
    }
    Reduce { state, action in
      return .none
    }
  }
}
