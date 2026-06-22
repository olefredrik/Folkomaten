// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Folkomaten",
    platforms: [.macOS(.v13)],
    targets: [
        // Ren logikk + innebygde data – testbar uten UI.
        .target(
            name: "FolkomatenKit",
            path: "Sources/FolkomatenKit",
            resources: [.process("Resources")]
        ),
        // SwiftUI menylinje-app.
        .executableTarget(
            name: "Folkomaten",
            dependencies: ["FolkomatenKit"],
            path: "Sources/Folkomaten"
        ),
        .testTarget(
            name: "FolkomatenKitTests",
            dependencies: ["FolkomatenKit"],
            path: "Tests/FolkomatenKitTests"
        ),
    ]
)
