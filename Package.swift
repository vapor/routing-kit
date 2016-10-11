import PackageDescription

let package = Package(
    name: "Routing",
    targets: [
        // Routing
        Target(name: "Routing"),
        Target(name: "HTTPRouting", dependencies: ["Routing"]),

        // Type Safe
        Target(name: "TypeSafeRouting", dependencies: ["Routing", "HTTPRouting"]),
        // Target(name: "TypeSafeGenerator"),
    ],
    dependencies: [
        // Core vapor transport layer
        .Package(url: "https://github.com/vapor/engine.git", majorVersion: 1),
        .Package(url: "https://github.com/vapor/node.git", majorVersion: 1)
    ],
    exclude: [
        "Sources/TypeSafeGenerator"
    ]
)
