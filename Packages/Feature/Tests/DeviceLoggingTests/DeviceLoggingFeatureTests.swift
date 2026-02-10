import FeatureCore
import SimulatorClient
import XCTest

@testable import DeviceLogging

@MainActor
final class DeviceLoggingFeatureTests: XCTestCase {
  func testOnAppearStartsLoggingWithSubsystemOrProcessPredicate() async {
    let recorder = PredicateRecorder()
    let store = TestStore(initialState: makeStateWithRunningApp()) {
      DeviceLoggingFeature().body
    } withDependencies: {
      $0[SimulatorClient.self].requestDevices = {
        .init(bootedDevices: [], shutdownGroups: [])
      }
      $0[SimulatorClient.self].startLogging = { _, predicate in
        await recorder.set(predicate)
        return AsyncThrowingStream { _ in }
      }
      $0[SimulatorClient.self].stopLogging = {}
    }

    await store.send(.view(.onAppear)) {
      $0.isViewVisible = true
      $0.isLogging = true
    }

    await store.receive(.local(.setDevices([]))) {
      $0.devices = []
    }

    XCTAssertEqual(
      await recorder.value,
      "subsystem == \"com.example.demo\" OR process == \"DemoApp\""
    )

    await store.send(.view(.onDisappear)) {
      $0.isViewVisible = false
      $0.isLogging = false
    }
  }

  func testConnectTappedReceivesLogs() async {
    let store = TestStore(initialState: makeStateWithRunningApp()) {
      DeviceLoggingFeature().body
    } withDependencies: {
      $0[SimulatorClient.self].startLogging = { _, _ in
        AsyncThrowingStream { continuation in
          continuation.yield("첫 번째 로그")
          continuation.yield("두 번째 로그")
          continuation.finish()
        }
      }
      $0[SimulatorClient.self].stopLogging = {}
    }

    await store.send(.view(.connectTapped(.sampleBooted))) {
      $0.connectedDevice = .sampleBooted
      $0.isLogging = true
    }

    await store.receive(.local(.logReceived("첫 번째 로그"))) {
      $0.logLines = ["첫 번째 로그"]
    }

    await store.receive(.local(.logReceived("두 번째 로그"))) {
      $0.logLines = ["첫 번째 로그", "두 번째 로그"]
    }

    await store.receive(.local(.loggingStopped)) {
      $0.isLogging = false
    }
  }

  func testConnectTappedShowsErrorLineWhenStreamFails() async {
    let store = TestStore(initialState: makeStateWithRunningApp()) {
      DeviceLoggingFeature().body
    } withDependencies: {
      $0[SimulatorClient.self].startLogging = { _, _ in
        AsyncThrowingStream { continuation in
          continuation.finish(
            throwing: SimulatorError.nonZeroExit(code: 1, description: "predicate error")
          )
        }
      }
      $0[SimulatorClient.self].stopLogging = {}
    }

    await store.send(.view(.connectTapped(.sampleBooted))) {
      $0.connectedDevice = .sampleBooted
      $0.isLogging = true
    }

    await store.receive(.local(.logReceived("[오류] 로그 스트림 실패: 명령이 비정상 종료되었습니다. 종료 코드: 1, predicate error"))) {
      $0.logLines = ["[오류] 로그 스트림 실패: 명령이 비정상 종료되었습니다. 종료 코드: 1, predicate error"]
    }

    await store.receive(.local(.loggingStopped)) {
      $0.isLogging = false
    }
  }

  func testLogLinesKeepLatestFiveHundred() async {
    let store = TestStore(initialState: .init()) {
      DeviceLoggingFeature().body
    }

    for index in 0..<501 {
      await store.send(.local(.logReceived("로그 \(index)")))
    }

    XCTAssertEqual(store.state.logLines.count, 500)
    XCTAssertEqual(store.state.logLines.first, "로그 1")
    XCTAssertEqual(store.state.logLines.last, "로그 500")
  }

  func testFilteredLogLinesReturnsAllWhenQueryIsEmpty() {
    var state = DeviceLoggingFeature.State()
    state.logLines = ["Network connected", "Request started"]
    state.searchQuery = ""

    XCTAssertEqual(state.filteredLogLines, ["Network connected", "Request started"])
  }

  func testSearchQueryFiltersLogsCaseInsensitive() async {
    var initialState = DeviceLoggingFeature.State()
    initialState.logLines = ["Network connected", "request started", "DB saved"]
    let store = TestStore(initialState: initialState) {
      DeviceLoggingFeature().body
    }

    await store.send(.view(.searchQueryChanged("REQUEST"))) {
      $0.searchQuery = "REQUEST"
    }

    XCTAssertEqual(store.state.filteredLogLines, ["request started"])
  }

  func testClearTappedClearsAllLogsAndKeepsStreamingState() async {
    var initialState = DeviceLoggingFeature.State()
    initialState.logLines = ["A", "B"]
    initialState.searchQuery = "A"
    initialState.isLogging = true
    initialState.isPaused = false
    let store = TestStore(initialState: initialState) {
      DeviceLoggingFeature().body
    }

    await store.send(.view(.clearTapped)) {
      $0.logLines = []
    }

    XCTAssertEqual(store.state.filteredLogLines, [])
    XCTAssertTrue(store.state.isLogging)
    XCTAssertFalse(store.state.isPaused)
    XCTAssertEqual(store.state.searchQuery, "A")
  }

  func testFilteredLogLinesReflectsNewIncomingLogsWithActiveQuery() async {
    let store = TestStore(initialState: .init()) {
      DeviceLoggingFeature().body
    }

    await store.send(.view(.searchQueryChanged("error"))) {
      $0.searchQuery = "error"
    }
    await store.send(.local(.logReceived("network started"))) {
      $0.logLines = ["network started"]
    }
    await store.send(.local(.logReceived("ERROR timeout"))) {
      $0.logLines = ["network started", "ERROR timeout"]
    }

    XCTAssertEqual(store.state.filteredLogLines, ["ERROR timeout"])
  }

  private func makeStateWithRunningApp() -> DeviceLoggingFeature.State {
    var state = DeviceLoggingFeature.State()
    state.$runningApp.withLock {
      $0 = .init(
        bundleId: "com.example.demo",
        processName: "DemoApp",
        displayName: "Demo",
        deviceId: "DEVICE-UDID"
      )
    }
    return state
  }
}

private actor PredicateRecorder {
  private(set) var value: String?

  func set(_ value: String?) {
    self.value = value
  }
}

private extension SimulatorDevice {
  static var sampleBooted: Self {
    .init(
      udid: "DEVICE-UDID",
      name: "iPhone 16",
      os: "18.2",
      state: .booted,
      isAvailable: true
    )
  }
}
