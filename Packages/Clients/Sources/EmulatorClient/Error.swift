import Foundation

public enum EmulatorError: Error {
  case noBootedDevice
  case notFound(path: String)
  case nonZeroExit(code: Int32, description: String)
}

extension EmulatorError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .noBootedDevice:
      return "실행 중인 Android 에뮬레이터가 없습니다."
    case let .notFound(path):
      return "실행 파일을 찾을 수 없습니다: \(path)"
    case let .nonZeroExit(code, description):
      let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmed.isEmpty {
        return "에뮬레이터 명령이 실패했습니다. 종료 코드: \(code)"
      }
      return "에뮬레이터 명령이 실패했습니다. 종료 코드: \(code), \(trimmed)"
    }
  }
}
