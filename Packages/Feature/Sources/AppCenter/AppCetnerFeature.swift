import AppBundleClient
import FeatureCore
import Foundation
import Toast
import UniformTypeIdentifiers

@Reducer
public struct AppCenterFeature {
  @ObservableState
  public struct State: Equatable {
    var models: [AppBundleCellModel] = []
    var isFileImporterPresented = false
    
    public init() {}
  }
  
  @CasePathable
  public enum Action: BindableAction, ViewAction {
    case binding(BindingAction<State>)
    case local(Local)
    case view(View)
    
    @CasePathable
    public enum Local {
      case setModels([AppBundleCellModel])
    }
    
    @CasePathable
    public enum View {
      case deviceTapped(AppBundle)
      case fileSelected(Result<URL, Error>)
      case installTapped(AppBundle)
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
    case let .setModels(models):
      state.models = models
      return .none
    }
  }
  
  private func view(
    _ state: inout State,
    _ action: Action.View
  ) -> Effect<Action> {
    switch action {
    case let .deviceTapped(appBundle):
      // TODO: - Show Device List
      print(appBundle)
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
      
    case let .installTapped(appBundle):
      // TODO: - Install App Bundle
      print(appBundle)
      return .none
      
    case .uploadTapped:
      state.isFileImporterPresented = true
      return .none
    }
  }
}
