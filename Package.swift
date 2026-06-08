// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NetworkGraph",
    platforms: [
        .macOS(.v10_13), .iOS(.v12)
     ],
    products: [
        .library(name: "NetworkGraph", targets: ["NetworkGraph"]),
        .executable(name: "net", targets: ["net"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.4.0"),
        .package(url: "https://github.com/johnsundell/files.git", from: "2.2.1"),
        .package(url: "https://github.com/SwiftDocOrg/GraphViz", from: "0.4.0"),
    ],
    targets: [
        .target(name: "NetworkGraph",
                dependencies: [
                    .product(name: "Files", package: "files"),
                    .product(name: "GraphViz", package: "GraphViz"),
                ],
//                exclude: ["TestData"],
                resources: [.process("TestData")]   // This has to be here, otherwise no `Bundle.module`.
        ),
        .testTarget(name: "NetworkGraphTests",
                    dependencies: [
                        "NetworkGraph",
                    ],
                    resources: [.copy("TestData")]
        ),
        .executableTarget(name: "net",
                dependencies: [
                    "NetworkGraph",
                    .product(name: "Files", package: "files"),
                    .product(name: "GraphViz", package: "GraphViz"),
                    .product(name: "ArgumentParser", package: "swift-argument-parser")
                ]
        )
    ]
)
