import FeatureCore
import Foundation
import SimulatorClient

@Reducer
public struct DeviceLoggingFeature {
  @ObservableState
  public struct State: Equatable {
    var connectedDevice: SimulatorDevice?
    var devices: [SimulatorDevice] = []
    
    public init() {}
  }
  
  @CasePathable
  public enum Action: ViewAction {
    case local(Local)
    case view(View)
    
    @CasePathable
    public enum Local {
      case disconnectDevice
      case logReceived(String)
      case reload
      case setDevices([SimulatorDevice])
    }
    
    @CasePathable
    public enum View {
      case connectTapped(SimulatorDevice)
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
    case .disconnectDevice:
      @Dependency(SimulatorClient.self) var client
      state.connectedDevice = nil
      return .run { _ in
        await client.stopLogging()
      }
      
    case let .logReceived(log):
      print(log)
      return .none
      
    case .reload:
      @Dependency(SimulatorClient.self) var client
      return .run { send in
        let devices = try await client
          .requestDevices()
          .filter { $0.state == .booted }
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
    case let .connectTapped(device):
      @Dependency(SimulatorClient.self) var client
      state.connectedDevice = device
      return .run { send in
        let stream = try await client.startLogging(udid: device.udid)
        for await log in stream {
          await send(.local(.logReceived(log)))
        }
        await send(.local(.disconnectDevice))
      } catch: { error, send in
        // TODO: - Handle Error
        print(error.localizedDescription)
        await send(.local(.disconnectDevice))
      }
      
    case .onAppear:
      return .send(.local(.reload))
    }
  }
}
