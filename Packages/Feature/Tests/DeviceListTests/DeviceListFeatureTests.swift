import EmulatorClient
import FeatureCore
import SimulatorClient
import XCTest

@testable import DeviceList

@MainActor
final class DeviceListFeatureTests: XCTestCase {
  func testAndroidBootUsesRawAVDName() async {
    let recorder = AndroidBootRecorder()
    let device = EmulatorDevice(
      serial: "avd:Medium_Phone_API_36.1",
      name: "Medium_Phone_API_36.1",
      avdName: "Medium_Phone_API_36.1",
      state: .shutdown
    )

    var initialState = DeviceListFeature.State()
    initialState.androidShutdownDevices = [device]

    let store = TestStore(initialState: initialState) {
      DeviceListFeature().body
    } withDependencies: {
      $0[EmulatorClient.self].bootDevice = { avdName in
        await recorder.recordBoot(avdName: avdName)
      }
      $0[EmulatorClient.self].requestDevices = {
        .init(bootedDevices: [], shutdownDevices: [device])
      }
      $0[SimulatorClient.self].requestDevices = {
        .init(bootedDevices: [], shutdownGroups: [])
      }
    }
    store.exhaustivity = .off

    await store.send(.view(.androidDeviceTapped(device)))
    await store.finish()

    let bootAVDName = await recorder.bootedAVDName()
    XCTAssertEqual(bootAVDName, "Medium_Phone_API_36.1")
  }
}

private actor AndroidBootRecorder {
  private var avdName: String?

  func recordBoot(avdName: String) {
    self.avdName = avdName
  }

  func bootedAVDName() -> String? {
    avdName
  }
}
