import FeatureCore
import XCTest

@testable import DevicePicker

@MainActor
final class DevicePickerFeatureTests: XCTestCase {
  func testDeviceTappedUpdatesCurrentDevice() async {
    let appBundle = AppBundle(
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
    let store = TestStore(
      initialState: DevicePickerFeature.State(appBundle: appBundle)
    ) {
      DevicePickerFeature().body
    }

    await store.send(.view(.deviceTapped(device))) {
      $0.current = device
    }
  }
}
