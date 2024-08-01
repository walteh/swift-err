import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

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
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.arguments.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description))"
    }
}


public struct ErrReturnMacro: ExpressionMacro {
	public static func expansion(
		of node: some FreestandingMacroExpansionSyntax,
//		providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
		in context: some MacroExpansionContext
	) -> ExprSyntax {
		let expression = node.arguments.first?.expression
		var argument = node.trailingClosure
		if argument == nil {
			argument = node.additionalTrailingClosures.first?.closure
		}

		if argument == nil {
			if expression != nil {
//				return """
//				Result(\(expression)).to(&err) else { return .failure(result.error(root: err)) }
//				"""
				return """
		Result(catching: \(argument) ).to(&err)
		"""			}
		}

		if argument == nil {
			fatalError("compiler bug: the macro does not have any closure arguments")
		}

//		return "Result(catching: \(argument) ).to(&err) else { return .failure(err!) }"
		return """
Result(catching: \(argument) ).to(&err)
"""

	}
}


public struct ErrReturndMacro: DeclarationMacro {

	public static func expansion(
		of node: some FreestandingMacroExpansionSyntax,
//		providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
		in context: some MacroExpansionContext
	) -> [SwiftSyntax.DeclSyntax] {
		let expression = node.arguments.first?.expression
		var argument = node.trailingClosure
		if argument == nil {
			argument = node.additionalTrailingClosures.first?.closure
		}

		if argument == nil {
			if expression != nil {
//				return """
//				Result(\(expression)).to(&err) else { return .failure(result.error(root: err)) }
//				"""
				return ["""
		let res = Result(catching: \(argument) ).to(&err); if err != nil { return .failure(err!) }
		"""]			}
		}

		if argument == nil {
			fatalError("compiler bug: the macro does not have any closure arguments")
		}

//		return "Result(catching: \(argument) ).to(&err) else { return .failure(err!) }"
		return ["""
let res = Result(catching: \(argument) ).to(&err); if err != nil { return .failure(err!) }
"""]

	}
}

@main
struct ErrMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
		ErrReturnMacro.self,
		ErrReturndMacro.self,
    ]
}
