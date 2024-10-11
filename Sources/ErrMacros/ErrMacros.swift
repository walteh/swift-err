import Foundation
import SwiftCompilerPlugin
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
@_spi(ExperimentalLanguageFeature) public import SwiftSyntaxMacros

private func generateGuardStatement(
	condition: OptionalBindingConditionSyntax,
	functionCall: String,
	guardStmt: GuardStmtSyntax
) -> String {
	let statements: String = "\(guardStmt.body)"
	let includeNSErr = statements.contains("nserr")
	let includeErr = statements.contains("err") || includeNSErr

	// Extract leading trivia as a string
	let guardLeadingTrivia = String(
		bytes: guardStmt.syntaxTextBytes.prefix(guardStmt.leadingTriviaLength.utf8Length),
		encoding: .utf8
	)!
	var bodyLeadingTrivia = String(
		bytes: guardStmt.body.statements.syntaxTextBytes.prefix(
			guardStmt.body.statements.leadingTriviaLength.utf8Length
		),
		encoding: .utf8
	)!

	if bodyLeadingTrivia.hasPrefix(guardLeadingTrivia) {
		bodyLeadingTrivia.trimPrefix(guardLeadingTrivia)
	}

	// Build the adjusted statements with correct trivia
	var states: [String] = []
	for stmt in guardStmt.body.statements {
		let stmtString = "\(stmt)".trimmingCharacters(in: .whitespacesAndNewlines)
		states.append("\n\(bodyLeadingTrivia)\(stmtString)")
	}

	let statementsd =
		"guard let \(condition.pattern)=\(functionCall) else {\n"
		+ "\(includeErr ? "\(bodyLeadingTrivia)let err = ___err!\n" : "")"
		+ "\(includeNSErr ? "\(bodyLeadingTrivia)let nserr = err as NSError\n" : "")"
		+ "\(states.joined(separator: ""))"
		+ "}"

	return statementsd
}

func expandMacro(
	in codeBlockItemList: CodeBlockItemListSyntax,
	file _: String,
	trace: Bool = false
) -> CodeBlockItemListSyntax {

	var newItems = [CodeBlockItemSyntax]()

	newItems.append("var ___err: Error? = nil")

	let toStatement = trace ? "___to___traced" : "___to"

	for item in codeBlockItemList {
		if let guardStmt = item.item.as(GuardStmtSyntax.self),
			let condition = guardStmt.conditions.first?.condition.as(
				OptionalBindingConditionSyntax.self
			)
		{
			if let tryExpr = condition.initializer?.value.as(TryExprSyntax.self) {
				let useAwait = tryExpr.expression.as(AwaitExprSyntax.self) != nil

				let full =
					"\(useAwait ? "await " : "")Result.___err___create(\(trace ? "tracing" : "catching"): {\ntry \(tryExpr.expression)\n}).\(toStatement)(&___err)"

				let expandedText = generateGuardStatement(
					condition: condition,
					functionCall: full,
					guardStmt: guardStmt
				)

				let expandedItem = Parser.parse(source: expandedText).statements

				newItems.append(contentsOf: expandedItem)

				continue
			} else if let functionCall = condition.initializer?.value.as(
				FunctionCallExprSyntax.self
			) {
				let functionCallTrimmed = "\(functionCall)".trimmingCharacters(
					in: .whitespacesAndNewlines
				)

				if functionCallTrimmed.hasSuffix(".get()") {
					let expandedText = generateGuardStatement(
						condition: condition,
						functionCall: "\(functionCallTrimmed.dropLast(6)).\(toStatement)(&___err)",
						guardStmt: guardStmt
					)
					let expandedItem = Parser.parse(source: expandedText).statements
					newItems.append(contentsOf: expandedItem)
					continue
				}
			} else if let functionCall = condition.initializer?.value.as(AwaitExprSyntax.self) {
				let functionCallTrimmed = "\(functionCall.expression)".trimmingCharacters(
					in: .whitespacesAndNewlines
				)

				if functionCallTrimmed.hasSuffix(".get()") {
					let expandedText = generateGuardStatement(
						condition: condition,
						functionCall:
							"await \(functionCallTrimmed.dropLast(6)).\(toStatement)(&___err)",
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
		if let selfdecl = declaration as? FunctionDeclSyntax {
			if let body = selfdecl.body {
				return expandMacro(in: body.statements, file: "\(body)") + []
			}
		}
		return []
	}
}

@_spi(ExperimentalLanguageFeature)
public struct ErrTraced: BodyMacro {
	public static func expansion(
		of _: AttributeSyntax,
		providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
		in _: some MacroExpansionContext
	) throws -> [CodeBlockItemSyntax] {
		if let selfdecl = declaration as? FunctionDeclSyntax {
			if let body = selfdecl.body {
				return expandMacro(in: body.statements, file: "\(body)", trace: true) + []
			}
		}
		return []
	}
}

@main
struct ErrMacroPlugin: CompilerPlugin {
	let providingMacros: [Macro.Type] = [
		Err.self,
		ErrTraced.self,
	]
}
