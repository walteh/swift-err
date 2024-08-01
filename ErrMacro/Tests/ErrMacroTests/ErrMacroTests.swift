import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(ErrMacroMacros)
import ErrMacroMacros

let testMacros: [String: Macro.Type] = [
    "stringify": StringifyMacro.self,
	"errreturn":  ErrReturnMacro.self,
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
            guard let res = #errreturn(performing: { try myThrowingFunc(12) }) else { return .failure(err!) }
            """,
            expandedSource: """
            guard let res = Result (catching: { try myThrowingFunc(12) }).to(&err) else { return .failure(err!) }
            """,
            macros: testMacros
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
