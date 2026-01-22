import DeviceList
import FeatureCore
import Foundation

@Reducer
public struct MainTabFeature {
  @ObservableState
  public struct State: Equatable {
    var currentTab: MainTabs
    var deviceList: DeviceListFeature.State = .init()
    
    public init(
      currentTab: MainTabs = .deviceList
    ) {
      self.currentTab = currentTab
    }
  }
  
  @CasePathable
  public enum Action: BindableAction, ViewAction {
    case binding(BindingAction<State>)
    case child(Child)
    case view(View)
    
    @CasePathable
    public enum Child {
      case deviceList(DeviceListFeature.Action)
    }
    
    @CasePathable
    public enum View {
      case tabSelected(MainTabs)
    }
  }
  
  public init() {}
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    Scope(state: \.deviceList, action: \.child.deviceList) {
      DeviceListFeature()
    }
    Reduce { state, action in
      switch action {
      case .binding:
        return .none
      case let .child(action):
        return child(&state, action)
      case let .view(action):
        return view(&state, action)
      }
    }
  }
  
  private func child(_ state: inout State, _ action: Action.Child) -> Effect<Action> {
    return .none
  }
  
  private func view(_ state: inout State, _ action: Action.View) -> Effect<Action> {
    switch action {
    case let .tabSelected(tab):
      state.currentTab = tab
      return .none
    }
  }
}
