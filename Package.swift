// swift-tools-version: 6.0
import PackageDescription

// A small, dependency-free regression suite for shared Foundation logic.
// The iOS app continues to build exclusively through its existing Xcode target.
let package = Package(
    name: "SpendyLogicChecks",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "SpendyLogic",
            path: "AppIOS",
            exclude: ["AppIOSApp.swift", "Constants.swift", "Extensions", "Media.xcassets",
                      "Services", "ViewModels", "Views", "Models/User.swift",
                      "Utils/CategoryMapper.swift", "Utils/Color+Extension.swift", "Utils/KeychainHelper.swift"],
            sources: ["Models/Expense.swift", "Utils/TransactionInput.swift"]
        ),
        .testTarget(name: "SpendyLogicTests", dependencies: ["SpendyLogic"], path: "Tests")
    ],
    swiftLanguageModes: [.v5]
)
