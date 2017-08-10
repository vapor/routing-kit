// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Routing",
    products: [
        .library(name: "Branches", targets: ["Branches"]),
        .library(name: "Routing", targets: ["Routing"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/engine.git", .upToNextMajor(from: "2.2.0")),
        .package(url: "https://github.com/vapor/core.git", .upToNextMajor(from: "2.1.2")),
        .package(url: "https://github.com/vapor/node.git", .upToNextMajor(from: "2.1.1")),
        .package(url: "https://github.com/vapor/debugging.git", .upToNextMajor(from: "1.1.0")),
    ],
    targets: [
        .target(name: "Branches", dependencies: ["Core", "Node"]),
        .testTarget(name: "BranchesTests", dependencies: ["Branches", "HTTP"]),
        .target(name: "Routing", dependencies: ["Branches", "HTTP", "WebSockets"]),
        .testTarget(name: "RoutingTests", dependencies: ["Routing"]),
    ]
)