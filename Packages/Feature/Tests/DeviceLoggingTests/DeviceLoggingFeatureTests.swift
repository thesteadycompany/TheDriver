import EmulatorClient
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

  func testAndroidOnAppearStartsLogging() async {
    let recorder = AndroidLoggingRecorder()
    let store = TestStore(initialState: makeStateWithAndroidRunningApp()) {
      DeviceLoggingFeature().body
    } withDependencies: {
      $0[SimulatorClient.self].requestDevices = {
        .init(bootedDevices: [], shutdownGroups: [])
      }
      $0[EmulatorClient.self].startLogging = { serial, packageName in
        await recorder.recordStart(serial: serial, packageName: packageName)
        return AsyncThrowingStream { continuation in
          continuation.yield("Android 첫 로그")
          continuation.finish()
        }
      }
      $0[EmulatorClient.self].stopLogging = {
        await recorder.recordStop()
      }
    }

    await store.send(.view(.onAppear)) {
      $0.isViewVisible = true
      $0.isLogging = true
    }

    await store.receive(.local(.setDevices([]))) {
      $0.devices = []
    }
    await store.receive(.local(.logReceived("Android 첫 로그"))) {
      $0.logLines = ["Android 첫 로그"]
    }
    await store.receive(.local(.loggingStopped)) {
      $0.isLogging = false
    }

    let start = await recorder.lastStart
    XCTAssertEqual(start?.serial, "emulator-5554")
    XCTAssertEqual(start?.packageName, "com.example.android")
  }

  func testAndroidConnectTappedShowsErrorLineWhenStreamFails() async {
    let store = TestStore(initialState: makeStateWithAndroidRunningApp()) {
      DeviceLoggingFeature().body
    } withDependencies: {
      $0[EmulatorClient.self].startLogging = { _, _ in
        AsyncThrowingStream { continuation in
          continuation.finish(
            throwing: EmulatorError.nonZeroExit(code: 1, description: "pid를 찾을 수 없습니다")
          )
        }
      }
    }

    await store.send(.view(.connectTapped(.sampleBooted))) {
      $0.connectedDevice = .sampleBooted
      $0.isLogging = true
    }

    await store.receive(.local(.logReceived("[오류] 로그 스트림 실패: 에뮬레이터 명령이 실패했습니다. 종료 코드: 1, pid를 찾을 수 없습니다"))) {
      $0.logLines = ["[오류] 로그 스트림 실패: 에뮬레이터 명령이 실패했습니다. 종료 코드: 1, pid를 찾을 수 없습니다"]
    }
    await store.receive(.local(.loggingStopped)) {
      $0.isLogging = false
    }
  }

  func testAndroidOnDisappearStopsLogging() async {
    let recorder = AndroidLoggingRecorder()
    let store = TestStore(initialState: makeStateWithAndroidRunningApp()) {
      DeviceLoggingFeature().body
    } withDependencies: {
      $0[EmulatorClient.self].startLogging = { _, _ in
        AsyncThrowingStream { _ in }
      }
      $0[EmulatorClient.self].stopLogging = {
        await recorder.recordStop()
      }
    }

    await store.send(.view(.onAppear)) {
      $0.isViewVisible = true
      $0.isLogging = true
    }
    await store.send(.view(.onDisappear)) {
      $0.isViewVisible = false
      $0.isLogging = false
    }

    XCTAssertEqual(await recorder.stopCount, 1)
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

  func testSearchQueryChangedClearsMatchesWhenQueryIsEmpty() async {
    let clock = TestClock()
    var initialState = DeviceLoggingFeature.State()
    initialState.logLines = ["Network connected", "request started"]
    initialState.searchInput = "request"
    initialState.searchQuery = "request"
    initialState.matchedLineIndices = [1]
    initialState.currentMatchPointer = 0
    let store = TestStore(initialState: initialState) {
      DeviceLoggingFeature().body
    } withDependencies: {
      $0.continuousClock = clock
    }

    await store.send(.view(.searchQueryChanged(""))) {
      $0.searchInput = ""
    }
    await clock.advance(by: .milliseconds(300))
    await store.receive(.local(.applySearchQuery(""))) {
      $0.searchQuery = ""
      $0.matchedLineIndices = []
      $0.currentMatchPointer = nil
    }
  }

  func testSearchQueryChangedBuildsMatchesAndFocusesLastMatch() async {
    let clock = TestClock()
    var initialState = DeviceLoggingFeature.State()
    initialState.logLines = ["abc-1", "other", "ABC-2", "abc-3"]
    let store = TestStore(initialState: initialState) {
      DeviceLoggingFeature().body
    } withDependencies: {
      $0.continuousClock = clock
    }

    await store.send(.view(.searchQueryChanged("abc"))) {
      $0.searchInput = "abc"
    }
    await clock.advance(by: .milliseconds(300))
    await store.receive(.local(.applySearchQuery("abc"))) {
      $0.searchQuery = "abc"
      $0.matchedLineIndices = [0, 2, 3]
      $0.currentMatchPointer = 2
    }
  }

  func testSearchSubmittedMovesBottomUpAndWraps() async {
    var initialState = DeviceLoggingFeature.State()
    initialState.logLines = ["abc-1", "other", "abc-2", "abc-3"]
    initialState.searchInput = "abc"
    initialState.searchQuery = "abc"
    initialState.matchedLineIndices = [0, 2, 3]
    initialState.currentMatchPointer = 2
    let store = TestStore(initialState: initialState) {
      DeviceLoggingFeature().body
    }
    await store.send(.view(.searchSubmitted)) {
      $0.currentMatchPointer = 1
      $0.searchNavigationTick = 1
    }
    await store.send(.view(.searchSubmitted)) {
      $0.currentMatchPointer = 0
      $0.searchNavigationTick = 2
    }
    await store.send(.view(.searchSubmitted)) {
      $0.currentMatchPointer = 2
      $0.searchNavigationTick = 3
    }
  }

  func testSearchPreviousTappedMovesTopDownAndWraps() async {
    var initialState = DeviceLoggingFeature.State()
    initialState.logLines = ["abc-1", "other", "abc-2", "abc-3"]
    initialState.searchInput = "abc"
    initialState.searchQuery = "abc"
    initialState.matchedLineIndices = [0, 2, 3]
    initialState.currentMatchPointer = 2
    let store = TestStore(initialState: initialState) {
      DeviceLoggingFeature().body
    }
    await store.send(.view(.searchPreviousTapped)) {
      $0.currentMatchPointer = 0
      $0.searchNavigationTick = 1
    }
    await store.send(.view(.searchPreviousTapped)) {
      $0.currentMatchPointer = 1
      $0.searchNavigationTick = 2
    }
    await store.send(.view(.searchPreviousTapped)) {
      $0.currentMatchPointer = 2
      $0.searchNavigationTick = 3
    }
  }

  func testSearchSubmittedIncrementsNavigationTickWhenOnlyOneMatch() async {
    var initialState = DeviceLoggingFeature.State()
    initialState.logLines = ["only", "other"]
    initialState.searchInput = "only"
    initialState.searchQuery = "only"
    initialState.matchedLineIndices = [0]
    initialState.currentMatchPointer = 0
    let store = TestStore(initialState: initialState) {
      DeviceLoggingFeature().body
    }
    await store.send(.view(.searchSubmitted)) {
      $0.currentMatchPointer = 0
      $0.searchNavigationTick = 1
    }
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
      $0.matchedLineIndices = []
      $0.currentMatchPointer = nil
    }

    XCTAssertTrue(store.state.isLogging)
    XCTAssertFalse(store.state.isPaused)
    XCTAssertEqual(store.state.searchQuery, "A")
  }

  func testSearchMatchesReflectNewIncomingLogsWithActiveQuery() async {
    var initialState = DeviceLoggingFeature.State()
    initialState.searchInput = "error"
    initialState.searchQuery = "error"
    let store = TestStore(initialState: initialState) {
      DeviceLoggingFeature().body
    }
    await store.send(.local(.logReceived("network started"))) {
      $0.logLines = ["network started"]
      $0.matchedLineIndices = []
      $0.currentMatchPointer = nil
    }
    await store.send(.local(.logReceived("ERROR timeout"))) {
      $0.logLines = ["network started", "ERROR timeout"]
      $0.matchedLineIndices = [1]
      $0.currentMatchPointer = 0
    }
  }

  func testSearchMatchSelectionSurvivesTrimByAdjustingLineIndex() async {
    var initialState = DeviceLoggingFeature.State()
    initialState.logLines = (0..<499).map { "로그 \($0)" } + ["target-log"]
    initialState.searchInput = "target"
    initialState.searchQuery = "target"
    initialState.matchedLineIndices = [499]
    initialState.currentMatchPointer = 0
    let store = TestStore(initialState: initialState) {
      DeviceLoggingFeature().body
    }
    await store.send(.local(.logReceived("새 로그")))

    XCTAssertEqual(store.state.logLines.count, 500)
    XCTAssertEqual(store.state.logLines.last, "새 로그")
    XCTAssertEqual(store.state.matchedLineIndices, [498])
    XCTAssertEqual(store.state.currentMatchPointer, 0)
  }

  private func makeStateWithRunningApp() -> DeviceLoggingFeature.State {
    var state = DeviceLoggingFeature.State()
    state.$runningApp.withLock {
      $0 = .init(
        platform: .ios,
        bundleId: "com.example.demo",
        processName: "DemoApp",
        displayName: "Demo",
        deviceId: "DEVICE-UDID"
      )
    }
    return state
  }

  private func makeStateWithAndroidRunningApp() -> DeviceLoggingFeature.State {
    var state = DeviceLoggingFeature.State()
    state.$runningApp.withLock {
      $0 = .init(
        platform: .android,
        bundleId: "com.example.android",
        processName: "com.example.android",
        displayName: "AndroidDemo",
        deviceId: "emulator-5554"
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

private actor AndroidLoggingRecorder {
  private(set) var lastStart: (serial: String, packageName: String)?
  private(set) var stopCount = 0

  func recordStart(serial: String, packageName: String) {
    lastStart = (serial, packageName)
  }

  func recordStop() {
    stopCount += 1
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
