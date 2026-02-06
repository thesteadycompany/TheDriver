import AppBundleClient
import CasePaths
import FeatureCore
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
      name: "Existing",
      url: URL(fileURLWithPath: "/tmp/Existing.app")
    )
    let newBundle = AppBundle(
      id: "com.example.new",
      name: "New",
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
      name: "Existing",
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
    XCTAssertEqual(toasts.first?.message, "지원하지 않는 파일입니다. (.app)")
    switch toasts.first?.style {
    case .warning:
      break
    default:
      XCTFail("Expected warning toast")
    }
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
