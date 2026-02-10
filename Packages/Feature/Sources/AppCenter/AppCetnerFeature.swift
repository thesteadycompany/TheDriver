import AppBundleClient
import DevicePicker
import EmulatorClient
import Entities
import FeatureCore
import Foundation
import SimulatorClient
import Toast
import UniformTypeIdentifiers

@Reducer
public struct AppCenterFeature {
  @ObservableState
  public struct State: Equatable {
    @Presents var devicePicker: DevicePickerFeature.State?
    @Shared(.runningApp) var runningApp: RunningApp?
    var models: IdentifiedArrayOf<AppBundleCellModel> = .init()
    var isFileImporterPresented = false
    
    public init() {}
  }
  
  @CasePathable
  public enum Action: BindableAction, ViewAction {
    case binding(BindingAction<State>)
    case child(Child)
    case local(Local)
    case view(View)
    
    @CasePathable
    public enum Child {
      case devicePicker(PresentationAction<DevicePickerFeature.Action>)
    }
    
    @CasePathable
    public enum Local {
      case setRunningApp(RunningApp?)
      case setModels([AppBundleCellModel])
    }
    
    @CasePathable
    public enum View {
      case deviceTapped(AppBundleCellModel)
      case fileSelected(Result<URL, Error>)
      case installTapped(AppBundleCellModel)
      case uploadTapped
    }
  }
  
  public init() {}
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        return .none
      case let .child(action):
        return child(&state, action)
      case let .local(action):
        return local(&state, action)
      case let .view(action):
        return view(&state, action)
      }
    }
    .ifLet(\.$devicePicker, action: \.child.devicePicker) {
      DevicePickerFeature()
    }
  }
  
  private func child(
    _ state: inout State,
    _ action: Action.Child
  ) -> Effect<Action> {
    switch action {
    case let .devicePicker(action):
      switch action {
      case let .presented(.delegate(action)):
        switch action {
        case let .saveTapped(appBundle, device):
          state.models[id: appBundle.id]?.device = device
          state.devicePicker = nil
          return .none
        }
        
      default:
        return .none
      }
    }
  }
  
  private func local(
    _ state: inout State,
    _ action: Action.Local
  ) -> Effect<Action> {
    switch action {
    case let .setRunningApp(runningApp):
      state.$runningApp.withLock { $0 = runningApp }
      return .none

    case let .setModels(models):
      state.models = .init(uniqueElements: models)
      return .none
    }
  }
  
  private func view(
    _ state: inout State,
    _ action: Action.View
  ) -> Effect<Action> {
    switch action {
    case let .deviceTapped(model):
      if model.appBundle.platform == .android {
        @Dependency(ToastClient.self) var toastClient
        toastClient.showWarning("Android는 실행 중인 에뮬레이터가 자동으로 선택됩니다.")
        return .none
      }
      state.devicePicker = .init(
        appBundle: model.appBundle,
        current: model.device
      )
      return .none
      
    case let .fileSelected(.success(url)):
      @Dependency(AppBundleClient.self) var client
      @Dependency(ToastClient.self) var toastClient
      return .runWithToast { send in
        do {
          let appBundle = try client.appBundle(url: url)
          // TODO: - Save App Bundle
          await send(.local(.setModels([.init(appBundle: appBundle)])))
        } catch let error as AppBundleError where error == .notSupportedFormat {
          toastClient.showWarning("지원하지 않는 파일입니다. (.app, .apk)")
          return
        } catch {
          throw error
        }
      }
      
    case let .fileSelected(.failure(error)):
      @Dependency(ToastClient.self) var toastClient
      toastClient.showError(error)
      return .none
      
    case let .installTapped(model):
      switch model.appBundle.platform {
      case .ios:
        return installiOSAppEffect(model)
      case .android:
        return installAndroidAppEffect(model)
      }

    case .uploadTapped:
      state.isFileImporterPresented = true
      return .none
    }
  }

  private func installiOSAppEffect(_ model: AppBundleCellModel) -> Effect<Action> {
    @Dependency(SimulatorClient.self) var client
    @Dependency(ToastClient.self) var toastClient
    guard let device = model.device else {
      toastClient.showWarning("선택된 기기가 없습니다.")
      return .none
    }
    return .runWithToast { send in
      try await client.installApp(
        udid: device.udid,
        appPath: model.appBundle.url.path()
      )
      _ = try await client.launchApp(
        device.udid,
        model.appBundle.id,
        [],
        .init()
      )
      await send(
        .local(
          .setRunningApp(
            .init(
              platform: .ios,
              bundleId: model.appBundle.id,
              processName: model.appBundle.executableName,
              displayName: model.appBundle.name,
              deviceId: device.udid
            )
          )
        )
      )
    }
  }

  private func installAndroidAppEffect(_ model: AppBundleCellModel) -> Effect<Action> {
    @Dependency(EmulatorClient.self) var client
    return .runWithToast { send in
      let devices = try await client.requestDevices()
      guard let device = devices.bootedDevices.first else {
        throw EmulatorError.noBootedDevice
      }
      try await client.installAPK(
        device.serial,
        model.appBundle.url.path()
      )
      try await client.launchApp(
        device.serial,
        model.appBundle.id
      )
      await send(
        .local(
          .setRunningApp(
            .init(
              platform: .android,
              bundleId: model.appBundle.id,
              processName: model.appBundle.id,
              displayName: model.appBundle.name,
              deviceId: device.serial
            )
          )
        )
      )
    }
  }
}
