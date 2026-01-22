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
    .package(path: "../Platform"),
    .package(path: "../Simulator"),
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
        .product(name: "DeviceList", package: "Simulator"),
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
