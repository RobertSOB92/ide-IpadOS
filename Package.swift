// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IDEApp",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "IDEApp",
            targets: ["IDEApp"]),
    ],
    dependencies: [
        // Git operations
        .package(url: "https://github.com/SwiftGit2/SwiftGit2.git", from: "0.9.0"),
        // Networking (optional, can use URLSession directly)
        // .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
    ],
    targets: [
        .target(
            name: "IDEApp",
            dependencies: [
                "SwiftGit2",
                // "Alamofire",
            ],
            path: "IDEApp"
        ),
        .testTarget(
            name: "IDEAppTests",
            dependencies: ["IDEApp"],
            path: "Tests"
        ),
    ]
)
