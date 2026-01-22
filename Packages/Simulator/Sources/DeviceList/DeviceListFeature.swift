import FeatureCore
import Foundation
import SimulatorClient

@Reducer
public struct DeviceListFeature {
  @ObservableState
  public struct State: Equatable {
    var devices: [SimulatorDevice] = []
    
    public init() {}
  }
  
  @CasePathable
  public enum Action: ViewAction {
    case local(Local)
    case view(View)
    
    @CasePathable
    public enum Local {
      case setDevices([SimulatorDevice])
    }
    
    @CasePathable
    public enum View {
      case onAppear
    }
  }
  
  public init() {}
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .local(action):
        return local(&state, action)
      case let .view(action):
        return view(&state, action)
      }
    }
  }
  
  private func local(_ state: inout State, _ action: Action.Local) -> Effect<Action> {
    switch action {
    case let .setDevices(devices):
      state.devices = devices
      return .none
    }
  }
  
  private func view(_ state: inout State, _ action: Action.View) -> Effect<Action> {
    switch action {
    case .onAppear:
      @Dependency(SimulatorClient.self) var client
      return .run { send in
        let devices = try await client.requestDevices()
        await send(.local(.setDevices(devices)))
      } catch: { error, send in
        // TODO: - Handle Error
        print(error.localizedDescription)
      }
    }
  }
}
