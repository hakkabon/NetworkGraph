// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NetworkGraph",
    platforms: [
        .macOS(.v12), .iOS(.v15), .macCatalyst(.v15)
     ],
    products: [
        .library(name: "NetworkGraph", targets: ["NetworkGraph"]),
        .executable(name: "net", targets: ["net"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.4.0"),
        .package(url: "https://github.com/johnsundell/files.git", from: "2.2.1"),
        .package(url: "https://github.com/SwiftDocOrg/GraphViz", from: "0.4.0"),
        // 0.0.3 is the first binding contract with rank constraints, stable edge ids,
        // assigned ranks, routed segments, and the dedicated bipartite entry point.
        .package(url: "https://github.com/hakkabon/Swift-Layout.git", exact: "0.0.3"),
    ],
    targets: [
        .target(name: "NetworkGraph",
                dependencies: [
                    .product(name: "Files", package: "files"),
                    .product(name: "GraphViz", package: "GraphViz"),
                    .product(name: "SwiftLayout", package: "Swift-Layout"),
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
