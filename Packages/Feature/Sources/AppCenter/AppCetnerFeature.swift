import AppBundleClient
import FeatureCore
import Foundation
import Toast
import UniformTypeIdentifiers

@Reducer
public struct AppCenterFeature {
  @ObservableState
  public struct State: Equatable {
    var isFileImporterPresented = false
    
    public init() {}
  }
  
  @CasePathable
  public enum Action: BindableAction, ViewAction {
    case binding(BindingAction<State>)
    case view(View)
    
    @CasePathable
    public enum View {
      case fileSelected(Result<URL, Error>)
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
      case let .view(action):
        return view(&state, action)
      }
    }
  }
  
  private func view(
    _ state: inout State,
    _ action: Action.View
  ) -> Effect<Action> {
    switch action {
    case let .fileSelected(.success(url)):
      @Dependency(AppBundleClient.self) var client
      return .runWithToast { send in
        let appBundle = try client.appBundle(url: url)
        // TODO: - Save App Bundle
      }
      
    case let .fileSelected(.failure(error)):
      @Dependency(ToastClient.self) var toastClient
      toastClient.showError(error)
      return .none
      
    case .uploadTapped:
      state.isFileImporterPresented = true
      return .none
    }
  }
}
