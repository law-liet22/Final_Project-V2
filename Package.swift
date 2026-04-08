// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "SwiftTaskApp",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "App", targets: ["App"]),
    ],
    dependencies: [
        // Hummingbird 2.0 - Lightweight Web Framework
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
        // SQLite.swift - Type-safe SQLite wrapper
        // SQLiteSwiftCSQLite trait embeds SQLite on Linux
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.5", traits: ["SQLiteSwiftCSQLite"]),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "SQLite", package: "SQLite.swift"),
            ],
            path: "Sources/App"
        ),
    ]
)