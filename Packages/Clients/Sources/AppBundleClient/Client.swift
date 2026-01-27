import DependenciesMacros
import Entities
import Foundation

@DependencyClient
public struct AppBundleClient: Sendable {
  public var appBundle: @Sendable (_ url: URL) throws -> AppBundle
}
