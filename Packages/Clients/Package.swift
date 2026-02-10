// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "Clients",
  platforms: [
    .macOS(.v15),
  ],
  products: [
    .singleTargetLibrary("AppBundleClient"),
    .singleTargetLibrary("DeveloperToolsClient"),
    .singleTargetLibrary("EmulatorClient"),
    .singleTargetLibrary("SimulatorClient"),
  ],
  dependencies: [
    .package(path: "../Platform"),
  ],
  targets: [
    .target(
      name: "AppBundleClient",
      dependencies: [
        .product(name: "ClientCore", package: "Platform")
      ]
    ),
    .target(
      name: "DeveloperToolsClient",
      dependencies: [
        .product(name: "ClientCore", package: "Platform")
      ]
    ),
    .target(
      name: "EmulatorClient",
      dependencies: [
        .product(name: "ClientCore", package: "Platform")
      ]
    ),
    .target(
      name: "SimulatorClient",
      dependencies: [
        .product(name: "ClientCore", package: "Platform")
      ]
    ),
    .testTarget(
      name: "EmulatorClientTests",
      dependencies: [
        "EmulatorClient",
      ]
    ),
  ]
)

extension Product {
  static func singleTargetLibrary(_ name: String) -> PackageDescription.Product {
    library(name: name, targets: [name])
  }
}
