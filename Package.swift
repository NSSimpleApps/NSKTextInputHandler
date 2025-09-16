// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "NSKTextInputHandler",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "NSKTextInputHandler", targets: ["NSKTextInputHandler"]),
        .library(name: "NSKTextInputHandler-Static", type: .static, targets: ["NSKTextInputHandler"]),
        .library(name: "NSKTextInputHandler-Dynamic", type: .dynamic, targets: ["NSKTextInputHandler"]),
    ],
    targets: [
        .target(
            name: "NSKTextInputHandler",
            path: "Sources"
        ),
    ],
    swiftLanguageModes: [.v6]
)
