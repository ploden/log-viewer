// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LogViewer",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        /*
        .executable(
            name: "LogViewer",
            targets: ["LogViewer"]
        ),
         */
        .library(name: "LogViewer", targets: ["LogViewer"])
    ],
    dependencies: [
        //.package(name: "ServiceProtocol", url: "https://github.com/ploden/service-protocol", from: "0.1.1")
    ],
    targets: [
        .target(
            name: "LogViewer",
            dependencies: [],
            //exclude: ["LogViewerDemo"],
            resources: [
                .process("Resources")
            ]
        ),
        /*
        .executableTarget(
            name: "LogViewer",
            dependencies: [],
            //exclude: ["LogViewerDemo"],
            resources: [
                .process("Resources")
            ]
        ),
         */
        .testTarget(
            name: "LogViewerTests",
            dependencies: ["LogViewer"]
        ),
    ]
) 
