import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(ErrMacros)
	@_spi(ExperimentalLanguageFeature) import ErrMacros

	let testMacros: [String: Macro.Type] = [
		"err": Err.self,
		"err_traced": ErrTraced.self,
	]
#endif

// func myThrowingFunc(_ arg: Int) throws -> UInt32 {
// 	return UInt32(arg)
// }

// func myResultFunc(_ arg: Int) -> Result<UInt32, Error> {
// 	return .success(UInt32(arg))
// }

final class ErrMacrosTests: XCTestCase {
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
						guard let res = Result.___err___create(catching: {
								try myThrowingFunc(12)
							}).___to(&___err) else {
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
					guard let res = myResultFunc(12).get() else {
						return .failure(err)
					}
					return .success(res)
				}
				""",
				expandedSource: """
					func hi() -> Result<String, Error> {
						var ___err: Error? = nil
						guard let res = myResultFunc(12).___to(&___err) else {
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
					guard let res = myResultFunc(12).get() else {
						print(err)
						return .failure(err)
					}
					return .success(res)
				}
				""",
				expandedSource: """
					func hi() -> Result<String, Error> {
						var ___err: Error? = nil
						guard let res = myResultFunc(12).___to(&___err) else {
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

	func testMacroDeepWithResultAndLargeBodyTraced() throws {
		#if canImport(ErrMacros)
			assertMacroExpansion(
				"""
				@err_traced func hi() -> Result<String, Error> {
					guard let res = myResultFunc(12).get() else {
						print(err)
						return .failure(err)
					}
					return .success(res)
				}
				""",
				expandedSource: """
					func hi() -> Result<String, Error> {
						var ___err: Error? = nil
						guard let res = myResultFunc(12).___to___traced(&___err) else {
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

	func testMacroDeepWithResultAndLargeBodyNested() throws {
		#if canImport(ErrMacros)
			assertMacroExpansion(
				"""
				@err func hi() -> Result<String, Error> {
					return myResultFunc({
						guard let res = myResultFunc(12).get() else {
							print(err)
							return .failure(err)
						}

						return .success(res)
					})
				}
				""",
				expandedSource: """
					func hi() -> Result<String, Error> {
						var ___err: Error? = nil
						return myResultFunc({
								var ___err: Error? = nil
								guard let res = myResultFunc(12).___to(&___err) else {
									let err = ___err!

									print(err)
									return .failure(err)
								}

										return .success(res)
							})
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
