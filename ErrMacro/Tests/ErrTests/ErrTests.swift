
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

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

@Test
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
					let nserr = err as NSError

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
