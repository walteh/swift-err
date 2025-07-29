// swift-tools-version: 6.2

import CompilerPluginSupport
import PackageDescription

let package = Package(
	name: "swift-err",
	platforms: [.macOS(.v26), .iOS(.v26), .tvOS(.v26), .watchOS(.v26), .macCatalyst(.v26)],
	products: [
		.library(
			name: "Err",
			targets: ["Err"]
		)

	],
	dependencies: [
		.package(url: "https://github.com/swiftlang/swift-testing.git", branch: "main"),
		.package(url: "https://github.com/apple/swift-atomics.git", branch: "main"),
	],

	targets: [
		.target(
			name: "Err",
			dependencies: [
				.product(name: "Atomics", package: "swift-atomics")
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
