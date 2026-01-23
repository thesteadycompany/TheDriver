import Foundation

enum SimctlCommand {
  case listDevices
  case boot(udid: String)
  case shutdown(udid: String)
  case shutdownAll
  case openSimulator(udid: String)
  
  var arguments: [String] {
    switch self {
    case .listDevices:
      return ["simctl", "list", "devices", "--json"]
    case let .boot(udid):
      return ["simctl", "boot", udid]
    case let .shutdown(udid):
      return ["simctl", "shutdown", udid]
    case .shutdownAll:
      return ["simctl", "shutdown", "all"]
    case let .openSimulator(udid):
      return ["simctl", "openurl", udid, "http://localhost/"] // or use `open -a Simulator`
    }
  }
}
