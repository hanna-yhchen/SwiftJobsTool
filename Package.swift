// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "SwiftJobsTool",
    platforms: [
        .macOS(.v12), .iOS(.v13)
    ],
    products: [
        .executable(
            name: "SwiftJobsCLT",
            targets: ["SwiftJobsTool"]
        ),
        .library(
            name: "SwiftJobsCore",
            targets: ["SwiftJobsToolCore"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "SwiftJobsTool",
            dependencies: ["SwiftJobsToolCore"],
            plugins: ["SwiftLintPlugin"]
        ),
        .target(
            name: "SwiftJobsToolCore",
            plugins: ["SwiftLintPlugin"]
        ),
        .testTarget(
            name: "SwiftJobsToolTests",
            dependencies: ["SwiftJobsTool"]
        ),
        .binaryTarget(
            name: "SwiftLintBinary",
            url: "https://github.com/realm/SwiftLint/releases/download/0.48.0/SwiftLintBinary-macos.artifactbundle.zip",
            checksum: "9c255e797260054296f9e4e4cd7e1339a15093d75f7c4227b9568d63edddba50"),
        .plugin(
            name: "SwiftLintPlugin",
            capability: .buildTool(),
            dependencies: ["SwiftLintBinary"]
        )
    ]
)
