// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ShowDesktop",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "ShowDesktop", targets: ["ShowDesktop"]),
    ],
    targets: [
        // Pure logic with no access to other apps or the screen, so it can be tested on its own.
        .target(name: "ShowDesktopCore"),
        .executableTarget(name: "ShowDesktop", dependencies: ["ShowDesktopCore"]),
        .testTarget(name: "ShowDesktopCoreTests", dependencies: ["ShowDesktopCore"]),
    ]
)
