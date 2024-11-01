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

							var ___err_1: Error? = nil; guard  let res = Result.___err___create(catching: {
								try myThrowingFunc(12)
							}).___to(&___err_1) else {
								let err: Error = ___err_1!
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
					let hello = 12
					guard let res = await myResultFunc(hello).get() [hello] else {
						return .failure(err)
					}
					return .success(res)
				}
				""",
				expandedSource: """
					func hi() -> Result<String, Error> {
						let hello = 12

							var ___err_1: Error? = nil; guard  let res = await Result.___err___create___sendable(catching: { [hello] in
								try await myResultFunc(hello).get()
							}).___to(&___err_1) else {
								let err: Error = ___err_1!
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
					guard let res = try myResultFunc(12).get() else {
						print(err)
						return .failure(err)
					}
					return .success(res)
				}
				""",
				expandedSource: """
					func hi() -> Result<String, Error> {

							var ___err_1: Error? = nil; guard  let res = Result.___err___create(catching: {
								try myResultFunc(12).get()
							}).___to(&___err_1) else {
								let err: Error = ___err_1!
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
					guard let res = try myResultFunc(12).get() else {
						print(err)
						return .failure(err)
					}
					return .success(res)
				}
				""",
				expandedSource: """
					func hi() -> Result<String, Error> {

							var ___err_1: Error? = nil; guard  let res = Result.___err___create(catching: {
								try myResultFunc(12).get()
							}).___to___traced(&___err_1) else {
								let err: Error = ___err_1!
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
				@err
				func hi() -> Result<String, Error> {
					return myResultFunc({
						guard let res = try myResultFunc(12).get() else {
							print(err)
							return .failure(err)
						}

						return .success(res)
					})
				}
				""",
				expandedSource: """
					func hi() -> Result<String, Error> {
					return myResultFunc({

							var ___err_1: Error? = nil; guard  let res = Result.___err___create(catching: {
								try myResultFunc(12).get()
							}).___to(&___err_1) else {
								let err: Error = ___err_1!
								print(err)
								return .failure(err)
							}

							return .success(res)
						})
					}
					""",
				macros: testMacros,
				indentationWidth: .tabs(0)
			)
		#else
			print("Skipping testMacroDeep because ErrMacroMacros is not available.")
		#endif
	}

	func testMacroDeepWithResultAndLargeBodyNestedFunc() throws {
		#if canImport(ErrMacros)
			assertMacroExpansion(
				"""
				@err
				func hi() -> Result<String, Error> {
					return myResultFunc({
						guard let res = try myResultFunc({
							guard let res = try myResultFunc(12).get() else {
								print(err)
								return .failure(err)
							}
							return .success(res)
						}).get() else {
							print(err)
							return .failure(err)
						}

						return .success(res)
					})
				}
				""",
				expandedSource: """
					func hi() -> Result<String, Error> {
					return myResultFunc({

							var ___err_2: Error? = nil; guard  let res = Result.___err___create(catching: {
								try myResultFunc({
								var ___err_1: Error? = nil; guard  let res = Result.___err___create(catching: {
									try myResultFunc(12).get()
								}).___to(&___err_1) else {
									let err: Error = ___err_1!
									print(err)
									return .failure(err)
								}
								return .success(res)
							}).get()
							}).___to(&___err_2) else {
								let err: Error = ___err_2!
								print(err)
								return .failure(err)
							}

							return .success(res)
						})
					}
					""",
				macros: testMacros,
				indentationWidth: .tabs(0)
			)
		#else
			print("Skipping testMacroDeep because ErrMacroMacros is not available.")
		#endif
	}
}
