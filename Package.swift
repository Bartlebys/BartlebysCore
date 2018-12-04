// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
// https://github.com/apple/swift-package-manager/blob/master/Documentation/PackageDescriptionV4.md

import PackageDescription

let package = Package(
    name: "BartlebysCore",
    products: [
        .library(name: "BartlebysCore", targets: ["BartlebysCore"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "BartlebysCore", dependencies: []),
        .testTarget( name: "BartlebysCoreTests", dependencies: ["BartlebysCore"]),
    ]
)
