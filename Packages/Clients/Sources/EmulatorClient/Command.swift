import Foundation

enum EmulatorCommand {
  case listDevices
  case listAVDs
  case installAPK(serial: String, apkPath: String)
  case launchApp(serial: String, packageName: String)

  var arguments: [String] {
    switch self {
    case .listDevices:
      return ["adb", "devices", "-l"]
    case .listAVDs:
      return ["emulator", "-list-avds"]
    case let .installAPK(serial, apkPath):
      return ["adb", "-s", serial, "install", "-r", apkPath]
    case let .launchApp(serial, packageName):
      return ["adb", "-s", serial, "shell", "monkey", "-p", packageName, "1"]
    }
  }
}
