// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BSTextEditor",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "BSTextEditor", targets: ["BSTextEditor"])
    ],
    targets: [
        .executableTarget(
            name: "BSTextEditor"
        )
    ]
)
