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
        //.package(url: "https://github.com/Bartlebys/BTree", from: "4.1.2"),
    ],
    targets: [
        .target(name: "BartlebysCore", dependencies: []),
        //.target(name: "BartlebysCore", dependencies: ["BTree"]),
        .testTarget( name: "BartlebysCoreTests", dependencies: ["BartlebysCore"]),
    ]
)
