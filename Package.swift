// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GlassReader",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "GlassReader", targets: ["GlassReader"])
    ],
    targets: [
        .executableTarget(
            name: "GlassReader",
            path: "Sources/GlassReader"
        )
    ]
)
