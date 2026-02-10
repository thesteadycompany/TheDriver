import EmulatorClient
import FeatureCore
import Foundation

@Reducer
public struct AndroidDevicePickerFeature {
  @ObservableState
  public struct State: Equatable {
    let appBundle: AppBundle
    var current: EmulatorDevice?
    var devices: [EmulatorDevice] = []

    public init(
      appBundle: AppBundle,
      current: EmulatorDevice? = nil
    ) {
      self.appBundle = appBundle
      self.current = current
    }
  }

  @CasePathable
  public enum Action: ViewAction {
    case delegate(Delegate)
    case local(Local)
    case view(View)

    @CasePathable
    public enum Delegate {
      case saveTapped(appBundle: AppBundle, device: EmulatorDevice)
    }

    @CasePathable
    public enum Local {
      case setDevices(EmulatorClient.Devices)
    }

    @CasePathable
    public enum View {
      case deviceTapped(EmulatorDevice)
      case onAppear
      case saveTapped
    }
  }

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .delegate:
        return .none
      case let .local(action):
        return local(&state, action)
      case let .view(action):
        return view(&state, action)
      }
    }
  }

  private func local(
    _ state: inout State,
    _ action: Action.Local
  ) -> Effect<Action> {
    switch action {
    case let .setDevices(devices):
      state.devices = devices.bootedDevices
      if let current = state.current,
         state.devices.contains(current) == false {
        state.current = nil
      }
      return .none
    }
  }

  private func view(
    _ state: inout State,
    _ action: Action.View
  ) -> Effect<Action> {
    switch action {
    case let .deviceTapped(device):
      state.current = device
      return .none

    case .onAppear:
      @Dependency(EmulatorClient.self) var client
      return .runWithToast { send in
        let devices = try await client.requestDevices()
        await send(.local(.setDevices(devices)))
      }

    case .saveTapped:
      guard let device = state.current else {
        return .none
      }
      return .send(
        .delegate(
          .saveTapped(appBundle: state.appBundle, device: device)
        )
      )
    }
  }
}
