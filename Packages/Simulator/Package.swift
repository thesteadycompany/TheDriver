// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "Simulator",
  products: [
    .singleTargetLibrary("Simulator")
  ],
  targets: [
    .target(
      name: "Simulator"
    ),
  ]
)

extension Product {
  static func singleTargetLibrary(_ name: String) -> PackageDescription.Product {
    library(name: name, targets: [name])
  }
}
