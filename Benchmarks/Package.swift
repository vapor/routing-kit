// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "benchmarks",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(path: "../"),
        .package(url: "https://github.com/ordo-one/package-benchmark.git", from: "1.22.0"),
    ],
    targets: [
        .executableTarget(
            name: "RouterPerformance",
            dependencies: [
                .product(name: "Benchmark", package: "package-benchmark"),
                .product(name: "RoutingKit", package: "routing-kit"),
            ],
            path: "RouterPerformance",
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
            ]
        )
    ]
)
