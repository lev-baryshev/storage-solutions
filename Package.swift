// swift-tools-version:5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package: Package = .init(
    name: "StorageSolutions",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "StorageSolutions", targets: ["StorageSolutions"])
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git",            exact: Version(6, 29, 1)),
        .package(url: "https://github.com/lev-baryshev/core-toolkit.git",   exact: Version(1, 0, 0))
    ],
    targets: [
        .target(
            name: "StorageSolutions",
            dependencies: [
                .product(name: "GRDB",          package: "GRDB.swift"),
                .product(name: "CoreToolkit",   package: "core-toolkit")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "StorageSolutionsTests",
            dependencies: ["StorageSolutions"],
            path: "Tests"
        )
    ]
)
