// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "IslandFlow",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "IslandFlow",
            targets: ["IslandFlow"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "IslandFlow",
            dependencies: [],
            path: "Sources/IslandFlow"
        )
    ]
)
