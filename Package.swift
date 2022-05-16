// swift-tools-version:5.4
import PackageDescription

let package = Package(
    name: "routing-kit",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .library(name: "RoutingKit", targets: ["RoutingKit"]),
    ],
    dependencies: [ ],
    targets: [
        .target(name: "RoutingKit"),
        .testTarget(name: "RoutingKitTests", dependencies: ["RoutingKit"]),
    ]
)
