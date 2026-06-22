// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Testborger",
    platforms: [.macOS(.v13)],
    targets: [
        // Ren logikk + innebygde data – testbar uten UI.
        .target(
            name: "TestborgerKit",
            path: "Sources/TestborgerKit",
            resources: [.process("Resources")]
        ),
        // SwiftUI menylinje-app.
        .executableTarget(
            name: "Testborger",
            dependencies: ["TestborgerKit"],
            path: "Sources/Testborger"
        ),
        .testTarget(
            name: "TestborgerKitTests",
            dependencies: ["TestborgerKit"],
            path: "Tests/TestborgerKitTests"
        ),
    ]
)
