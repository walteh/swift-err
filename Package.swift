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

		.executable(
			name: "ErrSamples",
			targets: ["ErrSamples"]
		),

	],
	dependencies: [
		.package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0-latest"),
		.package(url: "https://github.com/swiftlang/swift-testing.git", branch: "main"),
		.package(url: "https://github.com/swiftlang/swift-format.git", from: "600.0.0-latest"),
		.package(url: "https://github.com/apple/swift-log.git", branch: "main"),
	],

	targets: [

		.macro(
			name: "ErrMacros",
			dependencies: [
				.product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
				.product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
			]
		),

		.target(
			name: "Err",
			dependencies: [
				"ErrMacros",
				.product(name: "Logging", package: "swift-log"),
			]
		),

		.executableTarget(
			name: "ErrSamples",
			dependencies: ["Err"],
			swiftSettings: [
				.enableExperimentalFeature("BodyMacros")
			]
		),

		.testTarget(
			name: "ErrMacrosTests",
			dependencies: [
				"ErrMacros",
				.product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
				.product(name: "Testing", package: "swift-testing"),
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
