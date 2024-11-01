import Foundation
import SwiftCompilerPlugin
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct ErrMacroPlugin: CompilerPlugin {
	let providingMacros: [Macro.Type] = [
		Err.self,
		ErrTraced.self,
	]
}
