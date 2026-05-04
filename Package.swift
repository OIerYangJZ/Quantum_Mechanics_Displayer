// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "QuantumMechanicsLab",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "QuantumMechanicsLabCore",
            targets: ["QuantumMechanicsLabCore"]
        ),
        .executable(
            name: "QuantumMechanicsLabApp",
            targets: ["QuantumMechanicsLabApp"]
        ),
        .executable(
            name: "QuantumMechanicsLabCoreSmokeTests",
            targets: ["QuantumMechanicsLabCoreSmokeTests"]
        )
    ],
    targets: [
        .target(name: "QuantumMechanicsLabCore"),
        .executableTarget(
            name: "QuantumMechanicsLabApp",
            dependencies: ["QuantumMechanicsLabCore"]
        ),
        .executableTarget(
            name: "QuantumMechanicsLabCoreSmokeTests",
            dependencies: ["QuantumMechanicsLabCore"]
        ),
        .testTarget(
            name: "QuantumMechanicsLabCoreTests",
            dependencies: ["QuantumMechanicsLabCore"]
        )
    ]
)
