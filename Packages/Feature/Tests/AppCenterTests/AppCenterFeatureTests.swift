import AppBundleClient
import CasePaths
import EmulatorClient
import FeatureCore
import SimulatorClient
import Toast
import XCTest

@testable import AppCenter

@MainActor
final class AppCenterFeatureTests: XCTestCase {
  func testUploadTappedPresentsFileImporter() async {
    let store = TestStore(initialState: AppCenterFeature.State()) {
      AppCenterFeature().body
    }

    await store.send(.view(.uploadTapped)) {
      $0.isFileImporterPresented = true
    }
  }

  func testFileSelectedSuccessReplacesModels() async {
    let existingBundle = AppBundle(
      id: "com.example.existing",
      platform: .ios,
      name: "Existing",
      executableName: "Existing",
      url: URL(fileURLWithPath: "/tmp/Existing.app")
    )
    let newBundle = AppBundle(
      id: "com.example.new",
      platform: .ios,
      name: "New",
      executableName: "New",
      url: URL(fileURLWithPath: "/tmp/New.app")
    )
    var initialState = AppCenterFeature.State()
    initialState.models = .init(uniqueElements: [
      .init(appBundle: existingBundle),
    ])
    let store = TestStore(initialState: initialState) {
      AppCenterFeature().body
    } withDependencies: {
      $0[AppBundleClient.self].appBundle = { _ in newBundle }
      $0[ToastClient.self].show = { _ in }
    }

    let setModelsCasePath = AnyCasePath<AppCenterFeature.Action, [AppBundleCellModel]>(
      embed: { .local(.setModels($0)) },
      extract: { action in
        guard case let .local(.setModels(models)) = action else { return nil }
        return models
      }
    )

    await store.send(.view(.fileSelected(.success(newBundle.url))))
    await store.receive(setModelsCasePath) { state in
      state.models = .init(uniqueElements: [.init(appBundle: newBundle)])
    }
  }

  func testFileSelectedNotSupportedFormatShowsWarning() async {
    let existingBundle = AppBundle(
      id: "com.example.existing",
      platform: .ios,
      name: "Existing",
      executableName: "Existing",
      url: URL(fileURLWithPath: "/tmp/Existing.app")
    )
    let initialModels = IdentifiedArray(uniqueElements: [
      AppBundleCellModel(appBundle: existingBundle),
    ])
    let toastRecorder = ToastRecorder()
    var initialState = AppCenterFeature.State()
    initialState.models = initialModels
    let store = TestStore(initialState: initialState) {
      AppCenterFeature().body
    } withDependencies: {
      $0[AppBundleClient.self].appBundle = { _ in throw AppBundleError.notSupportedFormat }
      $0[ToastClient.self].show = { toast in
        Task { await toastRecorder.append(toast) }
      }
    }

    await store.send(.view(.fileSelected(.success(URL(fileURLWithPath: "/tmp/Invalid.txt")))))
    await store.finish()

    XCTAssertEqual(store.state.models, initialModels)

    let toasts = await toastRecorder.values()
    XCTAssertEqual(toasts.count, 1)
    XCTAssertEqual(toasts.first?.message, "지원하지 않는 파일입니다. (.app, .apk)")
    switch toasts.first?.style {
    case .warning:
      break
    default:
      XCTFail("Expected warning toast")
    }
  }

  func testInstallTappediOSSetsRunningApp() async {
    let bundle = AppBundle(
      id: "com.example.ios",
      platform: .ios,
      name: "iOSApp",
      executableName: "iOSApp",
      url: URL(fileURLWithPath: "/tmp/iOSApp.app")
    )
    let device = SimulatorDevice(
      udid: "SIM-UDID",
      name: "iPhone 16",
      os: "18.2",
      state: .booted,
      isAvailable: true
    )
    let model = AppBundleCellModel(appBundle: bundle, device: device)

    var initialState = AppCenterFeature.State()
    initialState.models = .init(uniqueElements: [model])

    let store = TestStore(initialState: initialState) {
      AppCenterFeature().body
    } withDependencies: {
      $0[SimulatorClient.self].installApp = { _, _ in }
      $0[SimulatorClient.self].launchApp = { _, _, _, _ in "ok" }
      $0[ToastClient.self].show = { _ in }
    }

    await store.send(.view(.installTapped(model)))
    await store.receive(.local(.setRunningApp(
      .init(
        platform: .ios,
        bundleId: "com.example.ios",
        processName: "iOSApp",
        displayName: "iOSApp",
        deviceId: "SIM-UDID"
      )
    )))
  }

  func testInstallTappedAndroidUsesEmulatorClient() async {
    let bundle = AppBundle(
      id: "com.example.android",
      platform: .android,
      name: "AndroidApp",
      executableName: "",
      url: URL(fileURLWithPath: "/tmp/AndroidApp.apk")
    )
    let model = AppBundleCellModel(appBundle: bundle)
    let recorder = InstallRecorder()

    var initialState = AppCenterFeature.State()
    initialState.models = .init(uniqueElements: [model])

    let store = TestStore(initialState: initialState) {
      AppCenterFeature().body
    } withDependencies: {
      $0[EmulatorClient.self].requestDevices = {
        .init(
          bootedDevices: [
            .init(serial: "EMU-1", name: "Pixel 8", state: .booted, apiLevel: 34)
          ],
          shutdownDevices: []
        )
      }
      $0[EmulatorClient.self].installAPK = { serial, path in
        await recorder.recordInstall(serial: serial, path: path)
      }
      $0[EmulatorClient.self].launchApp = { serial, package in
        await recorder.recordLaunch(serial: serial, package: package)
      }
      $0[ToastClient.self].show = { _ in }
    }

    await store.send(.view(.installTapped(model)))
    await store.receive(.local(.setRunningApp(
      .init(
        platform: .android,
        bundleId: "com.example.android",
        processName: "com.example.android",
        displayName: "AndroidApp",
        deviceId: "EMU-1"
      )
    )))

    let installed = await recorder.installed()
    XCTAssertEqual(installed.serial, "EMU-1")
    XCTAssertEqual(installed.path, "/tmp/AndroidApp.apk")

    let launched = await recorder.launched()
    XCTAssertEqual(launched.serial, "EMU-1")
    XCTAssertEqual(launched.appPackage, "com.example.android")
  }
}

private actor ToastRecorder {
  private var toasts: [Toast] = []

  func append(_ toast: Toast) {
    toasts.append(toast)
  }

  func values() -> [Toast] {
    toasts
  }
}

private actor InstallRecorder {
  private var installRecord: (serial: String, path: String)?
  private var launchRecord: (serial: String, appPackage: String)?

  func recordInstall(serial: String, path: String) {
    installRecord = (serial, path)
  }

  func recordLaunch(serial: String, package: String) {
    launchRecord = (serial, package)
  }

  func installed() -> (serial: String, path: String) {
    installRecord ?? ("", "")
  }

  func launched() -> (serial: String, appPackage: String) {
    launchRecord ?? ("", "")
  }
}
