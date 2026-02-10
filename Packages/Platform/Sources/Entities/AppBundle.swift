import Foundation

public struct AppBundle: Equatable, Identifiable, Sendable {
  /// Bundle ID
  public let id: String
  public let name: String
  public let executableName: String
  public let url: URL
  
  public init(
    id: String,
    name: String,
    executableName: String,
    url: URL
  ) {
    self.id = id
    self.name = name
    self.executableName = executableName
    self.url = url
  }
}
