// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PomodoroApp",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "PomodoroApp",
            path: "Sources/PomodoroApp"
        )
    ]
)
