import Foundation

public struct Toast: Sendable {
  public let style: ToastStyle
  public let delay: ToastDelay
  public let message: String
  
  public init(
    style: ToastStyle,
    delay: ToastDelay,
    message: String
  ) {
    self.style = style
    self.delay = delay
    self.message = message
  }
}

extension Toast {
  public static func plain(_ message: String) -> Self {
    return .init(
      style: .plain,
      delay: .short,
      message: message
    )
  }
  
  public static func success(_ message: String) -> Self {
    return .init(
      style: .success,
      delay: .short,
      message: message
    )
  }
  
  public static func failure(_ message: String) -> Self {
    return .init(
      style: .failure,
      delay: .long,
      message: message
    )
  }
  
  public static func warning(_ message: String) -> Self {
    return .init(
      style: .warning,
      delay: .long,
      message: message
    )
  }
}
