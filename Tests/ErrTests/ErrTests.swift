import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(ErrMacros)
	@_spi(ExperimentalLanguageFeature) import ErrMacros

	let testMacros: [String: Macro.Type] = [
		"err": Err.self,
	]
#endif

func myThrowingFunc(_ arg: Int) throws -> UInt32 {
	return UInt32(arg)
}

func myResultFunc(_ arg: Int) -> Result<UInt32, Error> {
	return .success(UInt32(arg))
}

final class ErrTests: XCTestCase {
	func testMacroDeep() throws {
		#if canImport(ErrMacros)
			assertMacroExpansion(
				"""
				@err func hi() -> Result<String, Error> { 
					guard let res = try myThrowingFunc(12) else {
						return .failure(err)
					}
					return .success(res)
				}
				""",
				expandedSource: """
				func hi() -> Result<String, Error> {
					var ___err: Error? = nil
					guard let res = Result.create(catching: {
							try myThrowingFunc(12)
						}).to(&___err) else {
						let err = ___err!

						return .failure(err)
					}
					return .success(res)
				}
				""",
				macros: testMacros,
				indentationWidth: .tab
			)
		#else
			print("Skipping testMacroDeep because ErrMacroMacros is not available.")
		#endif
	}

	func testMacroDeepWithResult() throws {
		#if canImport(ErrMacros)
			assertMacroExpansion(
				"""
				@err func hi() -> Result<String, Error> {
					guard let res = myResultFunc(12).err() else {
						return .failure(err)
					}
					return .success(res)
				}
				""",
				expandedSource: """
				func hi() -> Result<String, Error> {
					var ___err: Error? = nil
					guard let res = myResultFunc(12).to(&___err) else {
						let err = ___err!

						return .failure(err)
					}
					return .success(res)
				}
				""",
				macros: testMacros,
				indentationWidth: .tab
			)
		#else
			print("Skipping testMacroDeep because ErrMacroMacros is not available.")
		#endif
	}

	func testMacroDeepWithResultAndLargeBody() throws {
		#if canImport(ErrMacros)
			assertMacroExpansion(
				"""
				@err func hi() -> Result<String, Error> {
					guard let res = myResultFunc(12).err() else {
						print(err)
						return .failure(err)
					}
					return .success(res)
				}
				""",
				expandedSource: """
				func hi() -> Result<String, Error> {
					var ___err: Error? = nil
					guard let res = myResultFunc(12).to(&___err) else {
						let err = ___err!

						print(err)
						return .failure(err)
					}
					return .success(res)
				}
				""",
				macros: testMacros,
				indentationWidth: .tab
			)
		#else
			print("Skipping testMacroDeep because ErrMacroMacros is not available.")
		#endif
	}
}
