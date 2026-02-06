import AppBundleClient
import DevicePicker
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
          toastClient.showWarning("지원하지 않는 파일입니다. (.app)")
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
                bundleId: model.appBundle.id,
                displayName: model.appBundle.name,
                deviceId: device.udid
              )
            )
          )
        )
      }
      
    case .uploadTapped:
      state.isFileImporterPresented = true
      return .none
    }
  }
}
