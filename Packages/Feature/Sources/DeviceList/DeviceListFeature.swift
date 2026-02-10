import FeatureCore
import Foundation
import EmulatorClient
import SimulatorClient

@Reducer
public struct DeviceListFeature {
  @ObservableState
  public struct State: Equatable {
    var selectedFilter: DeviceFilter = .all
    var iOSBootedDevices: [SimulatorDevice] = []
    var iOSShutdownGroups: [DeviceGroup] = []
    var androidBootedDevices: [EmulatorDevice] = []
    var androidShutdownDevices: [EmulatorDevice] = []
    
    public init() {}

    var filteredIOSBootedDevices: [SimulatorDevice] {
      guard selectedFilter.showsIOS else { return [] }
      return iOSBootedDevices
    }

    var filteredIOSShutdownGroups: [DeviceGroup] {
      guard selectedFilter.showsIOS else { return [] }
      return iOSShutdownGroups
    }

    var filteredAndroidBootedDevices: [EmulatorDevice] {
      guard selectedFilter.showsAndroid else { return [] }
      return androidBootedDevices
    }

    var filteredAndroidShutdownDevices: [EmulatorDevice] {
      guard selectedFilter.showsAndroid else { return [] }
      return androidShutdownDevices
    }
  }
  
  public enum DeviceFilter: String, CaseIterable, Equatable, Sendable, Identifiable {
    case all
    case ios
    case android

    public var id: Self { self }

    var title: String {
      switch self {
      case .all: return "All"
      case .ios: return "iOS"
      case .android: return "Android"
      }
    }

    var showsIOS: Bool {
      self == .all || self == .ios
    }

    var showsAndroid: Bool {
      self == .all || self == .android
    }
  }

  @CasePathable
  public enum Action: ViewAction {
    case local(Local)
    case view(View)
    
    @CasePathable
    public enum Local {
      case reload
      case setIOSDevices(SimulatorClient.Devices)
      case setAndroidDevices(EmulatorClient.Devices)
    }
    
    @CasePathable
    public enum View {
      case filterTapped(DeviceFilter)
      case androidDeviceTapped(EmulatorDevice)
      case iOSDeviceTapped(SimulatorDevice)
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
      return .merge(reloadIOSDevices(), reloadAndroidDevices())
      
    case let .setIOSDevices(devices):
      state.iOSBootedDevices = devices.bootedDevices
      state.iOSShutdownGroups = devices.shutdownGroups
      return .none

    case let .setAndroidDevices(devices):
      state.androidBootedDevices = devices.bootedDevices
      state.androidShutdownDevices = devices.shutdownDevices
      return .none
    }
  }
  
  private func view(_ state: inout State, _ action: Action.View) -> Effect<Action> {
    switch action {
    case let .filterTapped(filter):
      state.selectedFilter = filter
      return .none

    case let .iOSDeviceTapped(device):
      @Dependency(SimulatorClient.self) var client
      switch device.state {
      case .booted:
        return .runWithToast { send in
          try client.shutdownDevice(udid: device.udid)
          await send(.local(.reload))
        }
        
      case .shutdown:
        return .runWithToast { send in
          try client.bootDevice(udid: device.udid)
          await send(.local(.reload))
        }
      }

    case let .androidDeviceTapped(device):
      @Dependency(EmulatorClient.self) var client
      switch device.state {
      case .booted:
        return .runWithToast { send in
          try await client.shutdownDevice(device.serial)
          await send(.local(.reload))
        }

      case .shutdown:
        return .runWithToast { send in
          try await client.bootDevice(device.avdName)
          await send(.local(.reload))
        }
      }
      
    case .onAppear:
      return .send(.local(.reload))
    }
  }

  private func reloadIOSDevices() -> Effect<Action> {
    @Dependency(SimulatorClient.self) var client
    return .runWithToast { send in
      let devices = try await client.requestDevices()
      await send(.local(.setIOSDevices(devices)))
    }
  }

  private func reloadAndroidDevices() -> Effect<Action> {
    @Dependency(EmulatorClient.self) var client
    return .runWithToast { send in
      let devices = try await client.requestDevices()
      await send(.local(.setAndroidDevices(devices)))
    }
  }
}
