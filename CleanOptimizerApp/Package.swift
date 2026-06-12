// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "CleanOptimizerApp",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "CleanOptimizerApp", targets: ["CleanOptimizerApp"])
    ],
    dependencies: [
        .package(url: "https://github.com/JohnSundell/ShellOut.git", from: "2.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "CleanOptimizerApp",
            dependencies: [
                .product(name: "ShellOut", package: "ShellOut")
            ],
            path: "Sources",
            exclude: [
                "CacheCleaner.swift.metadata.json",
                "CleanView.swift.metadata.json",
                "MainApp.swift.metadata.json",
                "MainView.swift.metadata.json",
                "OptimizeView.swift.metadata.json",
                "UninstallView.swift.metadata.json",
                "EmailCleaner.swift.metadata.json",
                "EmailView.swift.metadata.json"
            ]
        )
    ]
)
