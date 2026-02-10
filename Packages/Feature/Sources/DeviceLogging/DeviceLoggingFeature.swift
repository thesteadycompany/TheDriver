import Entities
import FeatureCore
import Foundation
import SimulatorClient

@Reducer
public struct DeviceLoggingFeature {
  @ObservableState
  public struct State: Equatable {
    @Shared(.runningApp) var runningApp: RunningApp? = nil
    var connectedDevice: SimulatorDevice?
    var devices: [SimulatorDevice] = []
    var logLines: [String] = []
    var searchQuery = ""
    var isLogging = false
    var isPaused = false
    var isViewVisible = false
    
    var filteredLogLines: [String] {
      guard searchQuery.isEmpty == false else { return logLines }
      return logLines.filter {
        $0.localizedCaseInsensitiveContains(searchQuery)
      }
    }
    
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
      case loggingStopped
      case reload
      case setDevices([SimulatorDevice])
    }
    
    @CasePathable
    public enum View {
      case clearTapped
      case connectTapped(SimulatorDevice)
      case onAppear
      case onDisappear
      case cancelTapped
      case searchQueryChanged(String)
    }
  }
  
  private enum CancelID {
    case logging
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
    .onChange(of: \.runningApp) { oldValue, newValue in
      Reduce { state, _ in
        guard oldValue != newValue else { return .none }
        state.isPaused = false
        state.logLines = []
        guard newValue != nil else {
          state.isLogging = false
          return stopLoggingEffect()
        }
        guard state.isViewVisible else { return .none }
        state.isLogging = false
        return .merge(
          stopLoggingEffect(),
          startLoggingEffect(&state)
        )
      }
    }
  }
  
  private func local(_ state: inout State, _ action: Action.Local) -> Effect<Action> {
    switch action {
    case .disconnectDevice:
      state.connectedDevice = nil
      state.isLogging = false
      return stopLoggingEffect()
      
    case let .logReceived(log):
      state.logLines.append(log)
      if state.logLines.count > 500 {
        state.logLines.removeFirst(state.logLines.count - 500)
      }
      return .none
      
    case .loggingStopped:
      state.isLogging = false
      return .none
      
    case .reload:
      @Dependency(SimulatorClient.self) var client
      return .runWithToast { send in
        let devices = try await client
          .requestDevices()
          .bootedDevices
        await send(.local(.setDevices(devices)))
      }
      
    case let .setDevices(devices):
      state.devices = devices
      return .none
    }
  }
  
  private func view(_ state: inout State, _ action: Action.View) -> Effect<Action> {
    switch action {
    case .clearTapped:
      state.logLines = []
      return .none
      
    case let .connectTapped(device):
      state.connectedDevice = device
      return startLoggingEffect(&state)
      
    case .onAppear:
      state.isViewVisible = true
      return .merge(
        .send(.local(.reload)),
        startLoggingEffect(&state)
      )
      
    case .onDisappear:
      state.isViewVisible = false
      state.isLogging = false
      return stopLoggingEffect()
      
    case .cancelTapped:
      state.isPaused = true
      state.isLogging = false
      return stopLoggingEffect()
      
    case let .searchQueryChanged(query):
      state.searchQuery = query
      return .none
    }
  }
  
  private func startLoggingEffect(_ state: inout State) -> Effect<Action> {
    @Dependency(SimulatorClient.self) var client
    guard let runningApp = state.runningApp, state.isPaused == false else { return .none }
    guard runningApp.platform == .ios else { return .none }
    state.isLogging = true
    let predicate = makeLogPredicate(runningApp: runningApp)
    return .run { send in
      do {
        let stream = try await client.startLogging(
          udid: runningApp.deviceId,
          predicate: predicate
        )
        for try await log in stream {
          await send(.local(.logReceived(log)))
        }
        await send(.local(.loggingStopped))
      } catch {
        await send(.local(.logReceived("[오류] 로그 스트림 실패: \(Self.errorDescription(error))")))
        await send(.local(.loggingStopped))
      }
    }
    .cancellable(id: CancelID.logging, cancelInFlight: true)
  }
  
  private func stopLoggingEffect() -> Effect<Action> {
    @Dependency(SimulatorClient.self) var client
    return .merge(
      .cancel(id: CancelID.logging),
      .run { _ in
        await client.stopLogging()
      }
    )
  }
  
  private func makeLogPredicate(runningApp: RunningApp) -> String {
    let bundleID = escapeLogPredicateValue(runningApp.bundleId)
    let processName = escapeLogPredicateValue(runningApp.processName)
    return "subsystem == \"\(bundleID)\" OR process == \"\(processName)\""
  }
  
  private func escapeLogPredicateValue(_ value: String) -> String {
    value
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\"", with: "\\\"")
  }
  
  private static func errorDescription(_ error: any Error) -> String {
    guard let error = error as? SimulatorError else {
      return error.localizedDescription
    }
    switch error {
    case let .notFound(path):
      return "xcrun 경로를 찾을 수 없습니다: \(path)"
    case let .nonZeroExit(code, description):
      let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmedDescription.isEmpty {
        return "명령이 비정상 종료되었습니다. 종료 코드: \(code)"
      }
      return "명령이 비정상 종료되었습니다. 종료 코드: \(code), \(trimmedDescription)"
    case let .invalidArguments(description):
      return "잘못된 로그 인자: \(description)"
    }
  }
}
