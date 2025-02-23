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
	],
	dependencies: [
		.package(url: "https://github.com/swiftlang/swift-testing.git", branch: "main"),
		.package(url: "https://github.com/swiftlang/swift-format.git", from: "600.0.0-latest"),
	],

	targets: [

		.target(
			name: "Err",
			dependencies: [

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
