// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VerticalPageScrollView",
    platforms: [
        .iOS(.v16) // only tested on iOS 16
    ],
    products: [
        .library(
            name: "VerticalPageScrollView",
            targets: ["VerticalPageScrollView"]),
    ],
    dependencies: [

    ],
    targets: [
        .target(
            name: "VerticalPageScrollView",
            dependencies: []),
    ]
)
