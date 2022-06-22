// swift-tools-version:5.4
import PackageDescription

let package = Package(
    name: "routing-kit",
    platforms: [
       .macOS(.v10_15),
       .iOS(.v11)
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
