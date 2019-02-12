// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "routing-kit",
    products: [
        .library(name: "RoutingKit", targets: ["RoutingKit"]),
    ],
    dependencies: [ ],
    targets: [
        .target(name: "RoutingKit"),
        .testTarget(name: "RoutingKitTests", dependencies: ["RoutingKit"]),
    ]
)
