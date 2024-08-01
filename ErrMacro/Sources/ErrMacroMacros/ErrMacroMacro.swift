import Foundation
import SwiftCompilerPlugin
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
@_spi(ExperimentalLanguageFeature) public import SwiftSyntaxMacros
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
		in _: some MacroExpansionContext
	) -> ExprSyntax {
		guard let argument = node.arguments.first?.expression else {
			fatalError("compiler bug: the macro does not have any arguments")
		}

		return "(\(argument), \(literal: argument.description))"
	}
}

// func expandMacro(in source: String) -> String {
//	// Define the regular expressions to match the specific patterns
//	let guardRegex = #"guard let (.*?) = try (.*?)\((.*?)\) else {"#
//	let failureRegex = #"return \.failure\(err\)"#
//
//	// Create the regular expression objects
//	guard let guardPattern = try? NSRegularExpression(pattern: guardRegex, options: []),
//		  let failurePattern = try? NSRegularExpression(pattern: failureRegex, options: []) else {
//		return source
//	}
//
//	// Replace the guard statement
//	let modifiedSource = guardPattern.stringByReplacingMatches(in: source, options: [], range: NSRange(source.startIndex..., in: source), withTemplate: """
//	guard let $1 = Result(catching: { try $2($3) }).to(&___err) else {
//		let err = ___err!
//		return .failure(err)
//	}
//	""")
//
//	// Replace the failure statement
//	let finalSource = failurePattern.stringByReplacingMatches(in: modifiedSource, options: [], range: NSRange(modifiedSource.startIndex..., in: modifiedSource), withTemplate: "return .failure(err)")
//
//	return finalSource
// }

import SwiftSyntax
import SwiftSyntaxBuilder

func expandMacro2(in codeBlockItemList: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
	var newItems = [CodeBlockItemSyntax]()

	newItems.append("var ___err: Error? = nil")

	for item in codeBlockItemList {
		if let guardStmt = item.item.as(GuardStmtSyntax.self),
		   let condition = guardStmt.conditions.first?.condition.as(OptionalBindingConditionSyntax.self),
		   let tryExpr = condition.initializer?.value.as(TryExprSyntax.self)

		{
			let functionCall = tryExpr.expression

			let expandedText = """
			guard let \(condition.pattern)= Result(catching: {
				try \(functionCall)
			}).to(&___err) else {
				let err = ___err!
				let nserr = err as NSError
				\(guardStmt.body.statements)
			}
			"""

//			var parser = Parser(source)
//			CodeBlockItemSyntax.parse(from: &parser)
			// Create a new syntax item with the expanded text
			let expandedItem = Parser.parse(source: expandedText).statements

//			let extraStatements =  [
//				"guard \(raw:expandedText) else {",
//				"let err = ___err!",
//			] + guardStmt.body.statements.dropFirst(0) + [
//				"}",
//			]

			// Add the expanded items to newItems
			newItems.append(contentsOf: expandedItem)

			// Skip adding the original item as it has been replaced
//					newItems.append(expandedItem)
			continue
//				}
//			}
		}
		newItems.append(item)
	}

	return CodeBlockItemListSyntax(newItems)
}

@_spi(ExperimentalLanguageFeature)
public struct ErrMacro: BodyMacro {
	public static func expansion(
		of _: AttributeSyntax,
		providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
		in _: some MacroExpansionContext
	) throws -> [CodeBlockItemSyntax] {
		let selfdecl = declaration as! FunctionDeclSyntax

		var data = ""

		if let body = selfdecl.body {
//			var items = [CodeBlockItemSyntax]()
			for i in body.statements {
//				print(expandMacro2(in: i))
				//				var item: ""
				//				switch i.item.kind {
				//				case .guardStmt:
				//
				//					for t in i.item.tokens(viewMode: .sourceAccurate) {
				//						if t.text == "try" {
				//							t.text = "Result(catching: { try"
				//						}
				//					}
				//
				//					let node = i.item.firstToken(viewMode: .sourceAccurate)
				//
				//					print("AHHHHH", i.item.kind, node?.text)
				//				default:
				//					print("kind: \(i.kind)")
				//					continue
				//
				//				}
				//
				//			}
			}
			print("sup", expandMacro2(in: body.statements))
			return expandMacro2(in: body.statements) + []
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
