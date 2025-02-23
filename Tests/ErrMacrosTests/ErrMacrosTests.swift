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
		"err_simple": ErrSimple.self,
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
				@err_traced func hi() -> Result<String, Error> {
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
							}).___to___traced(&___err_1) else {
								let err = ___err_1!
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
	func testMacroDeepNS() throws {
		#if canImport(ErrMacros)
			assertMacroExpansion(
				"""
				@err_traced func hi() -> Result<String, Error> {
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
							}).___to___traced(&___err_1) else {
								let err = ___err_1!
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
								let err = ___err_1!
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
								let err = ___err_1!
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
								let err = ___err_1!
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
								let err = ___err_1!
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
									let err = ___err_1!
									print(err)
									return .failure(err)
								}
								return .success(res)
							}).get()
							}).___to(&___err_2) else {
								let err = ___err_2!
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

	func testSimpleErrChecker() throws {
		#if canImport(ErrMacros)
			assertMacroExpansion(
				"""
				@err_simple
				func checker() async -> Result<String, Error> {
					guard let res2 = try myThrowingFunc(12) else {
						return .failure(err)
					}

					print(res2)

					guard let res3 = try myResultFunc(12).get() else {
						return .failure(err)
					}

					guard let res4 = try myThrowingFunc(12) else {
						return .failure(err)
					}

					guard let res5 = try await myThrowingAsyncFunc(12) else {
						return .failure(err)
					}

					guard let res6 = try await myResultAsyncFunc(12).get() else {
						return .failure(err)
					}

					guard let res7 = try myFunctionFunc({
						guard let res = try myResultFunc(12).get() else {
							throw Hello()
						}
						return res
					}) else {
						return .failure(err)
					}

					return .success("\\(res2) \\(res3) \\(res4) \\(res5) \\(res6) \\(res7)")
				}
				""",
				expandedSource: """
				func checker() async -> Result<String, Error> {
					var err__1: Error? = nil; guard let res2 = try myThrowingFunc(12) ?? err__1 else {
						let err = err__1!
						return .failure(err)
					}

					print(res2)

					var err__2: Error? = nil; guard let res3 = try myResultFunc(12).get() ?? err__2 else {
						let err = err__2!
						return .failure(err)
					}

					var err__3: Error? = nil; guard let res4 = try myThrowingFunc(12) ?? err__3 else {
						let err = err__3!
						return .failure(err)
					}

					var err__4: Error? = nil; guard let res5 = try await myThrowingAsyncFunc(12) ~> err__4 else {
						let err = err__4!
						return .failure(err)
					}

					var err__5: Error? = nil; guard let res6 = try await myResultAsyncFunc(12).get() ~> err__5 else {
						let err = err__5!
						return .failure(err)
					}

					var err__6: Error? = nil; guard let res7 = try myFunctionFunc({
						guard let res = try? myResultFunc(12).get() else {
							throw Hello()
						}
						return res
					}) ?? err__6 else {
						let err = err__6!
						return .failure(err)
					}

					return .success("\\(res2) \\(res3) \\(res4) \\(res5) \\(res6) \\(res7)")
				}
				""",
				macros: testMacros,
				indentationWidth: .tabs(1)
			)
		#else
			print("Skipping testSimpleErrChecker because ErrMacros is not available.")
		#endif
	}
}
