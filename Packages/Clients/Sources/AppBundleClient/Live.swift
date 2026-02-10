import Dependencies
import Entities
import Foundation

extension AppBundleClient: DependencyKey {
  public static let liveValue = AppBundleClient(
    appBundle: { url in
      guard
        url.pathExtension.lowercased() == "app",
        let bundle = Bundle(url: url),
        let identifier = bundle.bundleIdentifier,
        let executableName = bundle.executableName,
        let name = bundle.representedName
      else {
        throw AppBundleError.notSupportedFormat
      }
      return .init(
        id: identifier,
        name: name,
        executableName: executableName,
        url: url
      )
    }
  )
}

fileprivate extension Bundle {
  var representedName: String? {
    displayName ?? bundleName
  }
  
  var bundleName: String? {
    object(forInfoDictionaryKey: "CFBundleName") as? String
  }
  
  var displayName: String? {
    object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
  }

  var executableName: String? {
    object(forInfoDictionaryKey: "CFBundleExecutable") as? String
  }
}
