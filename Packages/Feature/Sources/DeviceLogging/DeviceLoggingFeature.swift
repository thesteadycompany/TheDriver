import Entities
import EmulatorClient
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
    var searchInput = ""
    var searchQuery = ""
    var matchedLineIndices: [Int] = []
    var currentMatchPointer: Int?
    var searchNavigationTick = 0
    var isLogging = false
    var isPaused = false
    var isViewVisible = false

    var currentMatchedLineIndex: Int? {
      guard
        let currentMatchPointer,
        matchedLineIndices.indices.contains(currentMatchPointer)
      else {
        return nil
      }
      return matchedLineIndices[currentMatchPointer]
    }
    
    public init() {}
  }
  
  @CasePathable
  public enum Action: ViewAction {
    case local(Local)
    case view(View)
    
    @CasePathable
    public enum Local {
      case applySearchQuery(String)
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
      case searchPreviousTapped
      case searchSubmitted
    }
  }
  
  private enum CancelID {
    case logging
    case searchDebounce
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
        state.searchInput = ""
        state.searchQuery = ""
        state.matchedLineIndices = []
        state.currentMatchPointer = nil
        state.searchNavigationTick = 0
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
    case let .applySearchQuery(query):
      state.searchQuery = query
      recomputeSearchMatches(&state, preserveCurrentSelection: false)
      return .none

    case .disconnectDevice:
      state.connectedDevice = nil
      state.isLogging = false
      return stopLoggingEffect()
      
    case let .logReceived(log):
      state.logLines.append(log)
      let removedLeadingLineCount = max(state.logLines.count - 500, 0)
      if removedLeadingLineCount > 0 {
        state.logLines.removeFirst(removedLeadingLineCount)
      }
      recomputeSearchMatches(
        &state,
        preserveCurrentSelection: true,
        removedLeadingLineCount: removedLeadingLineCount
      )
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
      recomputeSearchMatches(&state, preserveCurrentSelection: false)
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
      @Dependency(\.continuousClock) var clock
      state.searchInput = query
      return .run { send in
        try await clock.sleep(for: .milliseconds(300))
        await send(.local(.applySearchQuery(query)))
      }
      .cancellable(id: CancelID.searchDebounce, cancelInFlight: true)

    case .searchPreviousTapped:
      commitSearchInputIfNeeded(&state)
      moveSearchPointerTopDown(&state)
      return .cancel(id: CancelID.searchDebounce)

    case .searchSubmitted:
      commitSearchInputIfNeeded(&state)
      advanceSearchPointerBottomUp(&state)
      return .cancel(id: CancelID.searchDebounce)
    }
  }

  private func commitSearchInputIfNeeded(_ state: inout State) {
    guard state.searchInput != state.searchQuery else { return }
    state.searchQuery = state.searchInput
    recomputeSearchMatches(&state, preserveCurrentSelection: false)
  }

  private func recomputeSearchMatches(
    _ state: inout State,
    preserveCurrentSelection: Bool,
    removedLeadingLineCount: Int = 0
  ) {
    guard state.searchQuery.isEmpty == false else {
      state.matchedLineIndices = []
      state.currentMatchPointer = nil
      return
    }

    let previousSelectedLineIndex: Int? = {
      guard preserveCurrentSelection else { return nil }
      guard let currentMatchedLineIndex = state.currentMatchedLineIndex else { return nil }
      let adjustedLineIndex = currentMatchedLineIndex - removedLeadingLineCount
      return adjustedLineIndex >= 0 ? adjustedLineIndex : nil
    }()

    state.matchedLineIndices = state.logLines.enumerated().compactMap { index, line in
      line.localizedCaseInsensitiveContains(state.searchQuery) ? index : nil
    }

    guard state.matchedLineIndices.isEmpty == false else {
      state.currentMatchPointer = nil
      return
    }

    if
      let previousSelectedLineIndex,
      let preservedPointer = state.matchedLineIndices.firstIndex(of: previousSelectedLineIndex)
    {
      state.currentMatchPointer = preservedPointer
      return
    }

    state.currentMatchPointer = state.matchedLineIndices.count - 1
  }

  private func advanceSearchPointerBottomUp(_ state: inout State) {
    state.searchNavigationTick += 1
    guard state.matchedLineIndices.isEmpty == false else { return }
    guard let currentMatchPointer = state.currentMatchPointer else {
      state.currentMatchPointer = state.matchedLineIndices.count - 1
      return
    }
    state.currentMatchPointer =
      currentMatchPointer > 0
      ? currentMatchPointer - 1
      : state.matchedLineIndices.count - 1
  }

  private func moveSearchPointerTopDown(_ state: inout State) {
    state.searchNavigationTick += 1
    guard state.matchedLineIndices.isEmpty == false else { return }
    guard let currentMatchPointer = state.currentMatchPointer else {
      state.currentMatchPointer = 0
      return
    }
    state.currentMatchPointer =
      currentMatchPointer < state.matchedLineIndices.count - 1
      ? currentMatchPointer + 1
      : 0
  }
  
  private func startLoggingEffect(_ state: inout State) -> Effect<Action> {
    guard
      let runningApp = state.runningApp,
      !state.isPaused
    else {
      return .none
    }
    @Dependency(SimulatorClient.self) var simulatorClient
    let predicate = makeLogPredicate(runningApp: runningApp)
    state.isLogging = true
    return .run { send in
      do {
        let stream: AsyncThrowingStream<String, Error>
        switch runningApp.platform {
        case .ios:
          stream = try await simulatorClient.startLogging(
            udid: runningApp.deviceId,
            predicate: predicate
          )
        case .android:
          @Dependency(EmulatorClient.self) var emulatorClient
          stream = try await emulatorClient.startLogging(
            runningApp.deviceId,
            runningApp.bundleId
          )
        }
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
    @Dependency(SimulatorClient.self) var simulatorClient
    @Dependency(EmulatorClient.self) var emulatorClient
    return .merge(
      .cancel(id: CancelID.logging),
      .run { _ in
        await simulatorClient.stopLogging()
        await emulatorClient.stopLogging()
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
    if let simulatorError = error as? SimulatorError {
      switch simulatorError {
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
    if let emulatorError = error as? EmulatorError {
      switch emulatorError {
      case .noBootedDevice:
        return "실행 중인 Android 에뮬레이터가 없습니다."
      case let .notFound(path):
        return "실행 파일을 찾을 수 없습니다: \(path)"
      case let .nonZeroExit(code, description):
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedDescription.isEmpty {
          return "에뮬레이터 명령이 실패했습니다. 종료 코드: \(code)"
        }
        return "에뮬레이터 명령이 실패했습니다. 종료 코드: \(code), \(trimmedDescription)"
      }
    }
    return error.localizedDescription
  }
}
