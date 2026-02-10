import Dependencies
import Entities
import Foundation

extension AppBundleClient: DependencyKey {
  public static let liveValue = AppBundleClient(
    appBundle: { url in
      let fileExtension = url.pathExtension.lowercased()

      if fileExtension == "app" {
        guard
          let bundle = Bundle(url: url),
          let identifier = bundle.bundleIdentifier,
          let executableName = bundle.executableName,
          let name = bundle.representedName
        else {
          throw AppBundleError.notSupportedFormat
        }
        return .init(
          id: identifier,
          platform: .ios,
          name: name,
          executableName: executableName,
          url: url
        )
      }

      if fileExtension == "apk" {
        let fileName = url.deletingPathExtension().lastPathComponent
        guard fileName.isEmpty == false else {
          throw AppBundleError.notSupportedFormat
        }
        return .init(
          id: fileName,
          platform: .android,
          name: fileName,
          executableName: "",
          url: url
        )
      }

      throw AppBundleError.notSupportedFormat
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
