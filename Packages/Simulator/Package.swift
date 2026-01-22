// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "Simulator",
  platforms: [
    .macOS(.v15),
  ],
  products: [
    .singleTargetLibrary("DeviceList")
  ],
  dependencies: [
    .package(path: "../Platform"),
  ],
  targets: [
    .target(
      name: "DeviceList",
      dependencies: [
        "SimulatorClient",
        .product(name: "FeatureCore", package: "Platform"),
      ]
    ),
    .target(
      name: "SimulatorClient",
      dependencies: [
        .product(name: "ClientCore", package: "Platform")
      ]
    ),
  ]
)

extension Product {
  static func singleTargetLibrary(_ name: String) -> PackageDescription.Product {
    library(name: name, targets: [name])
  }
}
