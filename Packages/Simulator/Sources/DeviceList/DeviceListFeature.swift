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
      case reload
      case setDevices([SimulatorDevice])
    }
    
    @CasePathable
    public enum View {
      case deviceTapped(SimulatorDevice)
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
    case .reload:
      @Dependency(SimulatorClient.self) var client
      return .run { send in
        let devices = try await client.requestDevices()
        await send(.local(.setDevices(devices)))
      } catch: { error, send in
        // TODO: - Handle Error
        print(error.localizedDescription)
      }
      
    case let .setDevices(devices):
      state.devices = devices
      return .none
    }
  }
  
  private func view(_ state: inout State, _ action: Action.View) -> Effect<Action> {
    switch action {
    case let .deviceTapped(device):
      @Dependency(SimulatorClient.self) var client
      switch device.state {
      case .booted:
        return .run { send in
          try client.shutdownDevice(udid: device.udid)
          await send(.local(.reload))
        } catch: { error, send in
          // TODO: - Handle Error
          print(error.localizedDescription)
        }
        
      case .shutdown:
        return .run { send in
          try client.bootDevice(udid: device.udid)
          await send(.local(.reload))
        } catch: { error, send in
          // TODO: - Handle Error
          print(error.localizedDescription)
        }
      }
      
    case .onAppear:
      return .send(.local(.reload))
    }
  }
}
