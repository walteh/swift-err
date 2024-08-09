import Foundation
import SwiftCompilerPlugin
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
@_spi(ExperimentalLanguageFeature) public import SwiftSyntaxMacros
import SwiftSyntax

private func generateGuardStatement(
	condition: OptionalBindingConditionSyntax,
	functionCall: String,
	guardStmt: GuardStmtSyntax
) -> String {
	let statements: String = "\(guardStmt.body)"
	let includeNSErr = statements.contains("nserr")
	let includeErr = statements.contains("err") || includeNSErr

	// Extract leading trivia as a string
	let guardLeadingTrivia = String(bytes: guardStmt.syntaxTextBytes.prefix(guardStmt.leadingTriviaLength.utf8Length), encoding: .utf8)!
	var bodyLeadingTrivia = String(bytes: guardStmt.body.statements.syntaxTextBytes.prefix(guardStmt.body.statements.leadingTriviaLength.utf8Length), encoding: .utf8)!

	if bodyLeadingTrivia.hasPrefix(guardLeadingTrivia) {
		bodyLeadingTrivia.trimPrefix(guardLeadingTrivia)
	}

	// Build the adjusted statements with correct trivia
	var states: [String] = []
	for stmt in guardStmt.body.statements {
		let stmtString = "\(stmt)".trimmingCharacters(in: .whitespacesAndNewlines)
		states.append("\n\(bodyLeadingTrivia)\(stmtString)")
	}

	let statementsd = "guard let \(condition.pattern)=\(functionCall) else {\n"
		+ "\(includeErr ? "\(bodyLeadingTrivia)let err = ___err!\n" : "")"
		+ "\(includeNSErr ? "\(bodyLeadingTrivia)let nserr = err as NSError\n" : "")"
		+ "\(states.joined(separator: ""))"
		+ "}"

	return statementsd
}

func expandMacro(in codeBlockItemList: CodeBlockItemListSyntax, file _: String) -> CodeBlockItemListSyntax {
	var newItems = [CodeBlockItemSyntax]()

	newItems.append("var ___err: Error? = nil")

	for item in codeBlockItemList {
		if let guardStmt = item.item.as(GuardStmtSyntax.self),
		   let condition = guardStmt.conditions.first?.condition.as(OptionalBindingConditionSyntax.self)
		{
			if let tryExpr = condition.initializer?.value.as(TryExprSyntax.self) {
				let functionCall = tryExpr.expression

				let expandedText = generateGuardStatement(
					condition: condition,
					functionCall: "Result.create(catching: {\ntry \(functionCall)\n}).to(&___err)",
					guardStmt: guardStmt
				)

				let expandedItem = Parser.parse(source: expandedText).statements

				newItems.append(contentsOf: expandedItem)

				continue
			} else if let functionCall = condition.initializer?.value.as(FunctionCallExprSyntax.self) {
				let fc = "\(functionCall)".trimmingCharacters(in: .whitespacesAndNewlines)
				if fc.hasSuffix(".err()") {
					let expandedText = generateGuardStatement(
						condition: condition,
						functionCall: "\(fc.dropLast(6)).to(&___err)",
						guardStmt: guardStmt
					)
					let expandedItem = Parser.parse(source: expandedText).statements
					newItems.append(contentsOf: expandedItem)
					continue
				}
			}
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
