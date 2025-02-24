// swift-tools-version: 6.0

import CompilerPluginSupport
import PackageDescription

let package = Package(
	name: "swift-err",
	platforms: [.macOS(.v13), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
	products: [
		.library(
			name: "Err",
			targets: ["Err"]
		),
		.library(
			name: "LogDistributor",
			targets: ["LogDistributor"]
		),
		.library(
			name: "LogEvent",
			targets: ["LogEvent"]
		),

	],
	dependencies: [
		.package(url: "https://github.com/swiftlang/swift-testing.git", branch: "main"),
		.package(url: "https://github.com/swiftlang/swift-format.git", from: "600.0.0-latest"),
		.package(url: "https://github.com/apple/swift-log.git", from: "1.6.2"),
		.package(url: "https://github.com/apple/swift-service-context.git", from: "1.2.0"),
	],

	targets: [
		.target(
			name: "Err",
			dependencies: [
				.product(name: "Logging", package: "swift-log")
			]
		),

		.target(
			name: "LogDistributor",
			dependencies: [
				"LogEvent",
				.product(name: "Logging", package: "swift-log"),
				.product(name: "ServiceContextModule", package: "swift-service-context"),
			]
		),

		.target(
			name: "LogEvent",
			dependencies: [
				"Err",
				.product(name: "Logging", package: "swift-log"),
				.product(name: "ServiceContextModule", package: "swift-service-context"),
			]
		),

		.testTarget(
			name: "ErrTests",
			dependencies: [
				"Err",
				.product(name: "Testing", package: "swift-testing"),
			]
		),
	]
)
