// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "Platform",
  platforms: [
    .macOS(.v15),
  ],
  products: [
    .singleTargetLibrary("ClientCore"),
    .singleTargetLibrary("DesignSystem"),
    .singleTargetLibrary("FeatureCore"),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-dependencies", exact: "1.10.1"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", exact: "1.23.1"),
  ],
  targets: [
    .target(
      name: "ClientCore",
      dependencies: [
        "Entities",
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "DependenciesMacros", package: "swift-dependencies"),
      ]
    ),
    .target(
      name: "DesignSystem"
    ),
    .target(
      name: "Entities"
    ),
    .target(
      name: "FeatureCore",
      dependencies: [
        "DesignSystem",
        "Entities",
        "Toast",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .target(
      name: "Toast",
      dependencies: [
        "ClientCore",
        "DesignSystem",
      ]
    ),
  ]
)

extension Product {
  static func singleTargetLibrary(_ name: String) -> PackageDescription.Product {
    library(name: name, targets: [name])
  }
}
