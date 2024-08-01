import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
@_spi(ExperimentalLanguageFeature) public import SwiftSyntaxMacros

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
	public static func expansion(
		of node: some FreestandingMacroExpansionSyntax,
		in _: some MacroExpansionContext
	) -> ExprSyntax {
		guard let argument = node.arguments.first?.expression else {
			fatalError("compiler bug: the macro does not have any arguments")
		}

		return "(\(argument), \(literal: argument.description))"
	}
}

@_spi(ExperimentalLanguageFeature)
public struct ErrMacro: BodyMacro {
	public static func expansion(
		of _: AttributeSyntax,
		providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
		in _: some MacroExpansionContext
	) throws -> [CodeBlockItemSyntax] {
		let selfdecl = declaration as! FunctionDeclSyntax

		if let body = selfdecl.body {
			for i in body.statements {
				print(i)
			}
			return [
				"var err: Error? = nil",
			] + body.statements
		} else {
			return [
			]
		}
	}
}

@main
struct ErrMacroPlugin: CompilerPlugin {
	let providingMacros: [Macro.Type] = [
		StringifyMacro.self,
		ErrMacro.self,
	]
}
