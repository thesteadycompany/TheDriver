import Foundation

public enum ToastDelay: Sendable {
  case long
  case short
  case custom(Double)
  
  var seconds: Duration {
    switch self {
    case .long: return .seconds(3.5)
    case .short: return .seconds(2.0)
    case let .custom(delay): return .seconds(delay)
    }
  }
}
