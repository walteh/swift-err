// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
	name: "swift-err",
	platforms: [.macOS(.v13), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
	products: [
		// Products define the executables and libraries a package produces, making them visible to other packages.
		.library(
			name: "Err",
			targets: ["Err"]
		),
		.executable(
			name: "ErrClient",
			targets: ["ErrClient"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-syntax.git", from: "600.0.0-latest"),
		// swift testing
		.package(url: "https://github.com/apple/swift-testing.git", branch: "main"),
	],

	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		// Macro implementation that performs the source transformation of a macro.
		.macro(
			name: "ErrMacros",
			dependencies: [
				.product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
				.product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
			]
		),

		// Library that exposes a macro as part of its API, which is used in client programs.
		.target(name: "Err", dependencies: ["ErrMacros"]),

		// A client of the library, which is able to use the macro in its own code.
		.executableTarget(
			name: "ErrClient",
			dependencies: ["Err"],
			swiftSettings: [
				.enableExperimentalFeature("BodyMacros"),
			]
		),

		// A test target used to develop the macro implementation.
		.testTarget(
			name: "ErrTests",
			dependencies: [
				"ErrMacros",
				.product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
				.product(name: "Testing", package: "swift-testing"),
			]
		),
	]
)
