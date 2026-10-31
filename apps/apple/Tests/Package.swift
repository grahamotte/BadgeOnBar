// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BadgeOnBar",
    platforms: [.macOS(.v15)],
    targets: [
        .target(
            name: "BadgeOnBarCore",
            path: "App",
            sources: ["AppSettings.swift", "DebugCommand.swift"],
            swiftSettings: [.define("APP_DEV"), .swiftLanguageMode(.v5)],
        ),
        .testTarget(
            name: "BadgeOnBarCoreTests",
            dependencies: ["BadgeOnBarCore"],
            path: "Tests",
            exclude: ["Package.swift"],
            swiftSettings: [.swiftLanguageMode(.v5)],
        ),
    ]
)
