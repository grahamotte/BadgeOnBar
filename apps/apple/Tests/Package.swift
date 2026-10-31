// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "App",
    platforms: [.macOS(.v15)],
    targets: [
        .target(
            name: "AppCore",
            path: "App",
            exclude: ["App.swift", "AppView.swift", "Assets.xcassets", "Config", "DebugHooks.swift"],
            sources: ["DebugCommand.swift", "FocusTimer.swift"],
            swiftSettings: [.define("APP_DEV"), .swiftLanguageMode(.v5)],
        ),
        .testTarget(
            name: "AppCoreTests",
            dependencies: ["AppCore"],
            path: "Tests",
            exclude: ["Package.swift"],
            swiftSettings: [.swiftLanguageMode(.v5)],
        ),
    ]
)
