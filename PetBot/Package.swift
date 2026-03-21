// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PetBot",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "PetBot",
            targets: ["PetBot"]
        ),
    ],
    dependencies: [
        // 如需 Lottie 动画可添加
        // .package(url: "https://github.com/airbnb/lottie-spm.git", from: "4.4.0"),
    ],
    targets: [
        .executableTarget(
            name: "PetBot",
            dependencies: [],
            path: "PetBot",
            exclude: ["Assets.xcassets", "Info.plist", "a-export.png"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
    ]
)
