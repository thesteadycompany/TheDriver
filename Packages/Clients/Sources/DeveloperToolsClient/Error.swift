import Foundation

public enum DeveloperToolsError: Error {
  case notFound(path: String)
  case nonZeroExit(code: Int32, description: String)
  case failedToOpenURL(String)
}
