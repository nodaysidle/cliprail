// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ClipRail",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "ClipRail",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "ClipRailTests",
            dependencies: ["ClipRail"]
        )
    ]
)
