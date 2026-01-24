import Foundation

public enum SimulatorError: Error {
  case notFound(path: String)
  case nonZeroExit(code: Int32, description: String)
  case invalidArguments(description: String)
}
