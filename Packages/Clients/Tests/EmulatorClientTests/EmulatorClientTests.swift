import Entities
import XCTest

@testable import EmulatorClient

final class EmulatorClientTests: XCTestCase {
  func testParseADBDevicesOutput() {
    let output = """
    List of devices attached
    emulator-5554 device product:sdk_gphone64_arm64 model:sdk_gphone64_arm64 device:emu64a transport_id:1
    emulator-5556 offline transport_id:2
    """

    let devices = ADBDevicesParser().parse(output)

    XCTAssertEqual(devices.count, 2)
    XCTAssertEqual(devices[0].serial, "emulator-5554")
    XCTAssertEqual(devices[0].state, .booted)
    XCTAssertEqual(devices[1].serial, "emulator-5556")
    XCTAssertEqual(devices[1].state, .shutdown)
  }

  func testCommandArguments() {
    XCTAssertEqual(
      EmulatorCommand.installAPK(serial: "emu-1", apkPath: "/tmp/app.apk").arguments,
      ["adb", "-s", "emu-1", "install", "-r", "/tmp/app.apk"]
    )

    XCTAssertEqual(
      EmulatorCommand.launchApp(serial: "emu-1", packageName: "com.example.app").arguments,
      ["adb", "-s", "emu-1", "shell", "monkey", "-p", "com.example.app", "1"]
    )
  }
}
