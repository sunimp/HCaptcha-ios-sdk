// swift-tools-version:5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HCaptcha",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "HCaptcha",
            targets: ["HCaptcha"]
        ),
        .library(
            name: "HCaptcha_RxSwift",
            targets: ["HCaptcha_RxSwift"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift", .upToNextMajor(from: "6.7.1")),
        .package(url: "https://github.com/nicklockwood/SwiftFormat.git", from: "0.54.0"),
    ],
    targets: [
        .target(
            name: "HCaptcha",
            path: "HCaptcha",
            exclude: ["Classes/Rx"],
            resources: [
                .process("Resources/PrivacyInfo.xcprivacy")
            ],
            swiftSettings: [
                .unsafeFlags(["-Xlinker", "-w"])
            ]
        ),
        .target(
            name: "HCaptcha_RxSwift",
            dependencies: [
                "HCaptcha",
                .product(name: "RxSwift", package: "RxSwift")
            ],
            path: "HCaptcha/Classes/Rx",
            swiftSettings: [
                .unsafeFlags(["-Xlinker", "-w"])
            ]
        )
    ]
)
