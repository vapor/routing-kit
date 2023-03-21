// swift-tools-version:5.5.2
import PackageDescription

let package = Package(
    name: "routing-kit",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(name: "RoutingKit", targets: ["RoutingKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.2")
    ],
    targets: [
        .target(name: "RoutingKit", dependencies: [
            .product(name: "Logging", package: "swift-log"),
        ]),
        .testTarget(name: "RoutingKitTests", dependencies: ["RoutingKit"]),
    ]
)
