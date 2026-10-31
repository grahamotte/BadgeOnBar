// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "App",
    platforms: [.macOS(.v15)],
    targets: [
        .target(
            name: "App",
            path: "App",
            exclude: ["App.swift", "AppView.swift", "Assets.xcassets", "Config", "DebugHooks.swift"],
            sources: ["DebugCommand.swift", "FocusTimer.swift"],
            swiftSettings: [.define("APP_DEV")],
        ),
        .testTarget(name: "AppTests", dependencies: ["App"], path: "Tests", exclude: ["Package.swift"]),
    ]
)
