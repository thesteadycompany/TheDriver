import Entities
import XCTest

@testable import EmulatorClient

final class EmulatorClientTests: XCTestCase {
  func testParseADBDevicesOutput() {
    let output = """
    List of devices attached
    * daemon not running; starting now at tcp:5037
    * daemon started successfully
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

  func testParseAVDListOutput() {
    let output = """
    Pixel_8_API_34
    Small_Phone_API_35
    """

    let names = AVDListParser().parse(output)
    XCTAssertEqual(names, ["Pixel_8_API_34", "Small_Phone_API_35"])
  }

  func testCommandArguments() {
    XCTAssertEqual(EmulatorCommand.installAPK(serial: "emu-1", apkPath: "/tmp/app.apk").executableName, "adb")
    XCTAssertEqual(
      EmulatorCommand.installAPK(serial: "emu-1", apkPath: "/tmp/app.apk").arguments,
      ["-s", "emu-1", "install", "-r", "/tmp/app.apk"]
    )

    XCTAssertEqual(EmulatorCommand.launchApp(serial: "emu-1", packageName: "com.example.app").executableName, "adb")
    XCTAssertEqual(
      EmulatorCommand.launchApp(serial: "emu-1", packageName: "com.example.app").arguments,
      ["-s", "emu-1", "shell", "monkey", "-p", "com.example.app", "1"]
    )

    XCTAssertEqual(EmulatorCommand.bootDevice(avdName: "Pixel_8_API_34").executableName, "emulator")
    XCTAssertEqual(
      EmulatorCommand.bootDevice(avdName: "Pixel_8_API_34").arguments,
      ["-avd", "Pixel_8_API_34"]
    )

    XCTAssertEqual(EmulatorCommand.shutdownDevice(serial: "emulator-5554").executableName, "adb")
    XCTAssertEqual(
      EmulatorCommand.shutdownDevice(serial: "emulator-5554").arguments,
      ["-s", "emulator-5554", "emu", "kill"]
    )
  }
}
