import Foundation

public struct AppBundle: Equatable, Identifiable, Sendable {
  /// Bundle ID
  public let id: String
  public let name: String
  public let url: URL
  
  public init(
    id: String,
    name: String,
    url: URL
  ) {
    self.id = id
    self.name = name
    self.url = url
  }
}
