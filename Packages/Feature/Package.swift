// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "Feature",
  platforms: [
    .macOS(.v15),
  ],
  products: [
    .singleTargetLibrary("AppCenter"),
    .singleTargetLibrary("DeviceList"),
    .singleTargetLibrary("DeviceLogging"),
  ],
  dependencies: [
    .package(path: "../Clients"),
    .package(path: "../Platform"),
  ],
  targets: [
    .target(
      name: "AppCenter",
      dependencies: [
        .product(name: "FeatureCore", package: "Platform"),
        .product(name: "SimulatorClient", package: "Clients"),
      ]
    ),
    .target(
      name: "DeviceList",
      dependencies: [
        .product(name: "FeatureCore", package: "Platform"),
        .product(name: "SimulatorClient", package: "Clients"),
      ]
    ),
    .target(
      name: "DeviceLogging",
      dependencies: [
        .product(name: "FeatureCore", package: "Platform"),
        .product(name: "SimulatorClient", package: "Clients"),
      ]
    ),
  ]
)

extension Product {
  static func singleTargetLibrary(_ name: String) -> PackageDescription.Product {
    library(name: name, targets: [name])
  }
}
