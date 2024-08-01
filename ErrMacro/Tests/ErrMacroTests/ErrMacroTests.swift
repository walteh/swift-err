import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(ErrMacroMacros)
	@_spi(ExperimentalLanguageFeature) import ErrMacroMacros

	let testMacros: [String: Macro.Type] = [
		"stringify": StringifyMacro.self,
		"err": ErrMacro.self,
	]
#endif

func myThrowingFunc(_ arg: Int) throws -> UInt32 {
	return UInt32(arg)
}

final class ErrMacroTests: XCTestCase {
	func testMacro() throws {
		#if canImport(ErrMacroMacros)
			assertMacroExpansion(
				"""
				@err func hi() -> Result<String, Error> { return .success("hi") }
				""",
				expandedSource: """
				func hi() -> Result<String, Error> { var err: Error? = nil; return .success("hi") }
				""",
				macros: testMacros
			)
		#else
			throw XCTSkip("macros are only supported when running tests for the host platform")
		#endif
	}

	func testMacroDeep() throws {
		#if canImport(ErrMacroMacros)
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
					guard let res = Result(catching: {
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
			throw XCTSkip("macros are only supported when running tests for the host platform")
		#endif
	}

	func testMacroWithStringLiteral() throws {
		#if canImport(ErrMacroMacros)
			assertMacroExpansion(
				#"""
				#stringify("Hello, \(name)")
				"""#,
				expandedSource: #"""
				("Hello, \(name)", #""Hello, \(name)""#)
				"""#,
				macros: testMacros
			)
		#else
			throw XCTSkip("macros are only supported when running tests for the host platform")
		#endif
	}
}
