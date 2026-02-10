import FeatureCore
import XCTest

@testable import AndroidDevicePicker

@MainActor
final class AndroidDevicePickerFeatureTests: XCTestCase {
  func testDeviceTappedUpdatesCurrentDevice() async {
    let appBundle = AppBundle(
      id: "com.example.android",
      platform: .android,
      name: "AndroidApp",
      executableName: "",
      url: URL(fileURLWithPath: "/tmp/AndroidApp.apk")
    )
    let device = EmulatorDevice(
      serial: "EMU-1",
      name: "Pixel 8",
      state: .booted,
      apiLevel: 34
    )
    let store = TestStore(
      initialState: AndroidDevicePickerFeature.State(appBundle: appBundle)
    ) {
      AndroidDevicePickerFeature().body
    }

    await store.send(.view(.deviceTapped(device))) {
      $0.current = device
    }
  }
}
