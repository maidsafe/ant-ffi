// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// Release configuration - updated automatically by CI on release
let releaseTag = "0.0.15"
let releaseChecksum = "061a7168ad3f4591cc8e0d8373c97a2aff56085a533813dccbd75e039ca3273f"

// Use remote binary for releases, local path for development
let binaryTarget: Target
if !releaseTag.isEmpty {
    binaryTarget = .binaryTarget(
        name: "AutonomiCoreRS",
        url: "https://github.com/maidsafe/ant-ffi/releases/download/\(releaseTag)/libant_ffi-rs.xcframework.zip",
        checksum: releaseChecksum
    )
} else {
    // Local development: run `cd rust && ./build-ios.sh` first
    binaryTarget = .binaryTarget(
        name: "AutonomiCoreRS",
        path: "./rust/target/ios/libant_ffi-rs.xcframework"
    )
}

let package = Package(
    name: "Autonomi",
    platforms: [
        .iOS(.v16),
        .macOS(.v10_15),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Autonomi",
            targets: ["Autonomi"]
        ),
    ],
    targets: [
        binaryTarget,
        .target(
            name: "Autonomi",
            dependencies: [.target(name: "UniFFI")],
            path: "apple/Sources/Autonomi"
        ),
        .target(
            name: "UniFFI",
            dependencies: [.target(name: "AutonomiCoreRS")],
            path: "apple/Sources/UniFFI",
            linkerSettings: [
                .linkedFramework("SystemConfiguration"),
                .linkedFramework("Security"),
                .linkedFramework("CoreFoundation"),
                .linkedLibrary("resolv")
            ]
        ),
        .testTarget(
            name: "AutonomiTests",
            dependencies: ["Autonomi"],
            path: "apple/Tests/AutonomiTests"
        ),
    ]
)
