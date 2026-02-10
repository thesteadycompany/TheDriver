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
        let packageName = try APKMetadataExtractor.packageName(apkURL: url)
        return .init(
          id: packageName,
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

private enum APKMetadataExtractor {
  static func packageName(apkURL: URL) throws -> String {
    if let output = try runAPKAnalyzer(apkURL),
       let packageName = parseAPKAnalyzerPackageName(output),
       packageName.isEmpty == false {
      return packageName
    }

    if let output = try runAAPT(apkURL),
       let packageName = parseAAPTPackageName(output),
       packageName.isEmpty == false {
      return packageName
    }

    throw AppBundleError.notSupportedFormat
  }

  private static func runAPKAnalyzer(_ apkURL: URL) throws -> String? {
    guard let executableURL = resolveAPKAnalyzerExecutableURL() else { return nil }
    return try runProcess(
      executableURL: executableURL,
      arguments: ["manifest", "application-id", apkURL.path]
    )
  }

  private static func runAAPT(_ apkURL: URL) throws -> String? {
    guard let executableURL = resolveAAPTExecutableURL() else { return nil }
    return try runProcess(
      executableURL: executableURL,
      arguments: ["dump", "badging", apkURL.path]
    )
  }

  private static func runProcess(
    executableURL: URL,
    arguments: [String]
  ) throws -> String {
    let process = Process()
    process.executableURL = executableURL
    process.arguments = arguments

    let outPipe = Pipe()
    let errorPipe = Pipe()
    process.standardOutput = outPipe
    process.standardError = errorPipe

    try process.run()
    process.waitUntilExit()

    let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
    let stdOut = String(data: outData, encoding: .utf8) ?? ""
    let stdError = String(data: errorData, encoding: .utf8) ?? ""

    guard process.terminationStatus == 0 else {
      let message = stdError.isEmpty ? stdOut : stdError
      throw NSError(
        domain: "AppBundleClient.APKMetadataExtractor",
        code: Int(process.terminationStatus),
        userInfo: [NSLocalizedDescriptionKey: message]
      )
    }
    return stdOut
  }

  private static func resolveAPKAnalyzerExecutableURL() -> URL? {
    resolveExecutableURL(
      executableName: "apkanalyzer",
      toolPathsInSDK: [
        "cmdline-tools/latest/bin/apkanalyzer",
        "cmdline-tools/bin/apkanalyzer",
        "tools/bin/apkanalyzer",
      ]
    )
  }

  private static func resolveAAPTExecutableURL() -> URL? {
    let fileManager = FileManager.default
    for root in androidSDKRoots() {
      let buildToolsDirectory = (root as NSString).appendingPathComponent("build-tools")
      guard let versions = try? fileManager.contentsOfDirectory(atPath: buildToolsDirectory) else {
        continue
      }
      for version in versions.sorted(by: >) {
        let path = (buildToolsDirectory as NSString).appendingPathComponent("\(version)/aapt")
        if fileManager.isExecutableFile(atPath: path) {
          return URL(fileURLWithPath: path)
        }
      }
    }
    return resolveExecutableURL(executableName: "aapt", toolPathsInSDK: [])
  }

  private static func resolveExecutableURL(
    executableName: String,
    toolPathsInSDK: [String]
  ) -> URL? {
    let fileManager = FileManager.default
    var candidates: [String] = []

    for root in androidSDKRoots() {
      for toolPath in toolPathsInSDK {
        candidates.append((root as NSString).appendingPathComponent(toolPath))
      }
    }

    let pathVariable = ProcessInfo.processInfo.environment["PATH"] ?? ""
    for directory in pathVariable.split(separator: ":").map(String.init) {
      candidates.append((directory as NSString).appendingPathComponent(executableName))
    }

    var seen = Set<String>()
    for path in candidates where seen.insert(path).inserted {
      if fileManager.isExecutableFile(atPath: path) {
        return URL(fileURLWithPath: path)
      }
    }
    return nil
  }

  private static func androidSDKRoots() -> [String] {
    let environment = ProcessInfo.processInfo.environment
    return [
      environment["ANDROID_SDK_ROOT"],
      environment["ANDROID_HOME"],
      NSHomeDirectory().appending("/Library/Android/sdk"),
    ]
    .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
    .filter { $0.isEmpty == false }
  }
}

func parseAPKAnalyzerPackageName(_ output: String) -> String? {
  let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
  return trimmed.isEmpty ? nil : trimmed
}

func parseAAPTPackageName(_ output: String) -> String? {
  let pattern = "package: name='"
  guard let range = output.range(of: pattern) else { return nil }
  let substring = output[range.upperBound...]
  guard let closing = substring.firstIndex(of: "'") else { return nil }
  return String(substring[..<closing])
}
