// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Routing",
    products: [
        .library(name: "Routing", targets: ["Routing"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/engine.git", .branch("middleware")),
        .package(url: "https://github.com/vapor/core.git", .branch("beta")),
        .package(url: "https://github.com/vapor/debugging.git", .branch("beta")),
    ],
    targets: [
        .target(name: "Routing", dependencies: ["Core", "Debugging", "HTTP"]),
        .testTarget(name: "RoutingTests", dependencies: ["Routing"]),
    ]
)
