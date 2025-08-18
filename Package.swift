// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LogViewer",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .executable(
            name: "LogViewer",
            targets: ["LogViewer"]
        ),
    ],
    dependencies: [
        // Add any external dependencies here if needed
    ],
    targets: [
        .executableTarget(
            name: "LogViewer",
            dependencies: [],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "LogViewerTests",
            dependencies: ["LogViewer"]
        ),
    ]
) 