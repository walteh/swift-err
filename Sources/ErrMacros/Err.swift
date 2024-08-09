import Foundation
import SwiftCompilerPlugin
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
@_spi(ExperimentalLanguageFeature) public import SwiftSyntaxMacros
import SwiftSyntax

func expandMacro(in codeBlockItemList: CodeBlockItemListSyntax, file _: String) -> CodeBlockItemListSyntax {
	var newItems = [CodeBlockItemSyntax]()

	newItems.append("var ___err: Error? = nil")

	for item in codeBlockItemList {
		if let guardStmt = item.item.as(GuardStmtSyntax.self),
		   let condition = guardStmt.conditions.first?.condition.as(OptionalBindingConditionSyntax.self)
		{
			if let tryExpr = condition.initializer?.value.as(TryExprSyntax.self) {
				let functionCall = tryExpr.expression

				let expandedText = """
				guard let \(condition.pattern)= Result.create(catching: {
					try \(functionCall)
				}).to(&___err) else {
					let err = ___err!
					let nserr = err as NSError
					\(guardStmt.body.statements)
				}
				"""

				let expandedItem = Parser.parse(source: expandedText).statements

				newItems.append(contentsOf: expandedItem)

				continue
			} else if let functionCall = condition.initializer?.value.as(FunctionCallExprSyntax.self) {
				let fc = "\(functionCall)".trimmingCharacters(in: .whitespacesAndNewlines)
				if fc.hasSuffix(".err()") {
					let expandedText = """
						guard let \(condition.pattern)= \(fc.dropLast(6)).to(&___err) else {
						let err = ___err!
						let nserr = err as NSError
						\(guardStmt.body.statements)
					}
					"""

					let expandedItem = Parser.parse(source: expandedText).statements

					newItems.append(contentsOf: expandedItem)
					continue
				}
			}

			print(guardStmt.conditions)
		}
		newItems.append(item)
	}

	return CodeBlockItemListSyntax(newItems)
}

@_spi(ExperimentalLanguageFeature)
public struct Err: BodyMacro {
	public static func expansion(
		of _: AttributeSyntax,
		providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
		in _: some MacroExpansionContext
	) throws -> [CodeBlockItemSyntax] {
		let selfdecl = declaration as! FunctionDeclSyntax
		if let body = selfdecl.body {
			return expandMacro(in: body.statements, file: "\(body)") + []
		} else {
			return []
		}
	}
}

@main
struct ErrMacroPlugin: CompilerPlugin {
	let providingMacros: [Macro.Type] = [
		Err.self,
	]
}
