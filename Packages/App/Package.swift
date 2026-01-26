// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "App",
  platforms: [
    .macOS(.v15),
  ],
  products: [
    .singleTargetLibrary("App"),
  ],
  dependencies: [
    .package(path: "../Feature"),
    .package(path: "../Platform"),
  ],
  targets: [
    .target(
      name: "App",
      dependencies: [
        "MainTab",
      ]
    ),
    .target(
      name: "MainTab",
      dependencies: [
        .product(name: "AppCenter", package: "Feature"),
        .product(name: "DeviceList", package: "Feature"),
        .product(name: "DeviceLogging", package: "Feature"),
        .product(name: "FeatureCore", package: "Platform"),
      ]
    )
  ]
)

extension Product {
  static func singleTargetLibrary(_ name: String) -> PackageDescription.Product {
    library(name: name, targets: [name])
  }
}
