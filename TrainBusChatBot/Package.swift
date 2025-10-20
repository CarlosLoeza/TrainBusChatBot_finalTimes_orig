
// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "TrainBusChatBot",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "TrainBusChatBot",
            targets: ["TrainBusChatBot"])
    ],
    dependencies: [
        .package(url: "https://github.com/yaslab/CSV.swift.git", from: "2.4.3")
    ],
    targets: [
        .target(
            name: "TrainBusChatBot",
            dependencies: [
                .product(name: "CSV", package: "CSV.swift")
            ],
            path: "TrainBusChatBot")
    ]
)
