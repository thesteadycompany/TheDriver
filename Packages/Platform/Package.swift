// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "Platform",
  platforms: [
    .macOS(.v15),
  ],
  products: [
    .singleTargetLibrary("FeatureCore"),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", exact: "1.23.1"),
  ],
  targets: [
    .target(
      name: "FeatureCore",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
  ]
)

extension Product {
  static func singleTargetLibrary(_ name: String) -> PackageDescription.Product {
    library(name: name, targets: [name])
  }
}
