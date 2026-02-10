import XCTest

@testable import AppBundleClient

final class AppBundleClientTests: XCTestCase {
  func testParseAPKAnalyzerPackageName() {
    let output = "com.example.app\n"
    XCTAssertEqual(parseAPKAnalyzerPackageName(output), "com.example.app")
  }

  func testParseAPKAnalyzerPackageNameWithEmptyOutput() {
    XCTAssertNil(parseAPKAnalyzerPackageName("\n\n"))
  }

  func testParseAAPTPackageName() {
    let output = "package: name='com.example.app' versionCode='1' versionName='1.0'"
    XCTAssertEqual(parseAAPTPackageName(output), "com.example.app")
  }

  func testParseAAPTPackageNameWithUnexpectedOutput() {
    XCTAssertNil(parseAAPTPackageName("application-label:'Demo'"))
  }
}
