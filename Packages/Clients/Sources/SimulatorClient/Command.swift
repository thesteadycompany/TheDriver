import Foundation

enum SimctlCommand {
  case listDevices
  case boot(udid: String)
  case bootStatus(udid: String)
  case shutdown(udid: String)
  case shutdownAll
  case openSimulator(udid: String)
  case install(udid: String, appPath: String)
  case launch(udid: String, bundleId: String, arguments: [String], options: SimulatorClient.LaunchOptions)
  
  var arguments: [String] {
    switch self {
    case .listDevices:
      return ["simctl", "list", "devices", "--json"]
    case let .boot(udid):
      return ["simctl", "boot", udid]
    case let .bootStatus(udid):
      return ["simctl", "bootstatus", udid, "-b"]
    case let .shutdown(udid):
      return ["simctl", "shutdown", udid]
    case .shutdownAll:
      return ["simctl", "shutdown", "all"]
    case let .openSimulator(udid):
      return ["simctl", "openurl", udid, "http://localhost/"] // or use `open -a Simulator`
    case let .install(udid, appPath):
      return ["simctl", "install", udid, appPath]
    case let .launch(udid, bundleId, arguments, options):
      var args: [String] = ["simctl", "launch"]

      if options.waitForDebugger {
        args.append("--wait-for-debugger")
      }

      if options.console {
        args.append("--console")
      } else {
        if let stdoutPath = options.stdoutPath {
          args.append("--stdout=\(stdoutPath)")
        }
        if let stderrPath = options.stderrPath {
          args.append("--stderr=\(stderrPath)")
        }
      }

      if options.terminateRunningProcess {
        args.append("--terminate-running-process")
      }

      args.append(udid)
      args.append(bundleId)
      args.append(contentsOf: arguments)
      return args
    }
  }
}
