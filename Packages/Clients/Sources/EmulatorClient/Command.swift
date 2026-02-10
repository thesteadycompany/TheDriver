import Foundation

enum EmulatorCommand {
  case startADBServer
  case listDevices
  case listAVDs
  case bootDevice(avdName: String)
  case shutdownDevice(serial: String)
  case installAPK(serial: String, apkPath: String)
  case launchApp(serial: String, packageName: String)
  case runningAVDName(serial: String)

  var executableName: String {
    switch self {
    case .listAVDs, .bootDevice:
      return "emulator"
    case .startADBServer, .listDevices, .shutdownDevice, .installAPK, .launchApp, .runningAVDName:
      return "adb"
    }
  }

  var arguments: [String] {
    switch self {
    case .startADBServer:
      return ["start-server"]
    case .listDevices:
      return ["devices", "-l"]
    case .listAVDs:
      return ["-list-avds"]
    case let .bootDevice(avdName):
      return ["-avd", avdName]
    case let .shutdownDevice(serial):
      return ["-s", serial, "emu", "kill"]
    case let .installAPK(serial, apkPath):
      return ["-s", serial, "install", "-r", apkPath]
    case let .launchApp(serial, packageName):
      return ["-s", serial, "shell", "monkey", "-p", packageName, "1"]
    case let .runningAVDName(serial):
      return ["-s", serial, "emu", "avd", "name"]
    }
  }
}
