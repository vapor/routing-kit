// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "routing",
    products: [
        .library(name: "Routing", targets: ["Routing"]),
    ],
    dependencies: [ ],
    targets: [
        .target(name: "Routing", dependencies: []),
        .testTarget(name: "RoutingTests", dependencies: ["Routing"]),
    ]
)
