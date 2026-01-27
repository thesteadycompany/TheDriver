import AppBundleClient
import DevicePicker
import FeatureCore
import Foundation
import Toast
import UniformTypeIdentifiers

@Reducer
public struct AppCenterFeature {
  @ObservableState
  public struct State: Equatable {
    @Presents var devicePicker: DevicePickerFeature.State?
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
      return .runWithToast { send in
        let appBundle = try client.appBundle(url: url)
        // TODO: - Save App Bundle
        await send(.local(.setModels([.init(appBundle: appBundle)])))
      }
      
    case let .fileSelected(.failure(error)):
      @Dependency(ToastClient.self) var toastClient
      toastClient.showError(error)
      return .none
      
    case let .installTapped(model):
      // TODO: - Install App Bundle
      print(model)
      return .none
      
    case .uploadTapped:
      state.isFileImporterPresented = true
      return .none
    }
  }
}
