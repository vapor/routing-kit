import PackageDescription

let package = Package(
    name: "Routing",
    targets: [
        // Routing
        Target(name: "Branches"),
        Target(name: "Routing", dependencies: ["Branches"]),
    ],
    dependencies: [
        // Core vapor transport layer
        .Package(url: "https://github.com/vapor/engine.git", Version(2,0,0, prereleaseIdentifiers: ["beta"])),
        .Package(url: "https://github.com/vapor/node.git", Version(2,0,0, prereleaseIdentifiers: ["beta"]))
    ],
    exclude: [
        "Sources/TypeSafeGenerator"
    ]
)
