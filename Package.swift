// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Routing",
    products: [
        .library(name: "Branches", targets: ["Branches"]),
        .library(name: "Routing", targets: ["Routing"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/engine.git", .branch("beta")),
        .package(url: "https://github.com/vapor/core.git", .branch("beta")),
        .package(url: "https://github.com/vapor/debugging.git", .branch("beta")),
    ],
    targets: [
        .target(name: "Branches", dependencies: ["Core"]),
        .testTarget(name: "BranchesTests", dependencies: ["Branches", "HTTP"]),
        .target(name: "Routing", dependencies: ["Branches", "HTTP", "WebSockets"]),
        .testTarget(name: "RoutingTests", dependencies: ["Routing"]),
    ]
)