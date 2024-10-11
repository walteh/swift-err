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
	trace: Bool = false,
	extras: Bool = true
) -> CodeBlockItemListSyntax {
	var newItems = [CodeBlockItemSyntax]()
	if extras {
		newItems.append("var ___err: Error? = nil\n")
	}

	let toStatement = trace ? "___to___traced" : "___to"

	func processClosureExpr(_ closureExpr: ClosureExprSyntax) -> ClosureExprSyntax {
		let processedStatements = expandMacro(
			in: closureExpr.statements,
			file: "\(closureExpr.statements)",
			trace: trace,
			extras: true
		)
		return closureExpr.with(\.statements, processedStatements)
	}

	for item in codeBlockItemList {
		if let guardStmt = item.item.as(GuardStmtSyntax.self),
			let condition = guardStmt.conditions.first?.condition.as(
				OptionalBindingConditionSyntax.self
			)
		{

			if let tryExpr = condition.initializer?.value.as(TryExprSyntax.self) {
				let useAwait = tryExpr.expression.as(AwaitExprSyntax.self) != nil

				var expr = tryExpr.expression

				if let functionCall = tryExpr.expression.as(FunctionCallExprSyntax.self) {
					var newArguments = [LabeledExprSyntax]()
					for arg in functionCall.arguments {
						if let closureExpr = arg.expression.as(ClosureExprSyntax.self) {
							let processedClosure = processClosureExpr(closureExpr)
							newArguments.append(
								arg.with(\.expression, ExprSyntax(processedClosure))
							)
						} else {
							newArguments.append(arg)
						}
					}
					let newFunctionCall = functionCall.with(
						\.arguments,
						LabeledExprListSyntax(newArguments)
					)

					expr = ExprSyntax(newFunctionCall)
				}

				let full =
					"\(useAwait ? "await " : "")Result.___err___create(\(trace ? "tracing" : "catching"): {\ntry \(expr)\n}).\(toStatement)(&___err)"

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
				var newArguments = [LabeledExprSyntax]()
				for arg in functionCall.arguments {
					if let closureExpr = arg.expression.as(ClosureExprSyntax.self) {
						let processedClosure = processClosureExpr(closureExpr)
						newArguments.append(arg.with(\.expression, ExprSyntax(processedClosure)))
					} else {
						newArguments.append(arg)
					}
				}
				let newFunctionCall = functionCall.with(
					\.arguments,
					LabeledExprListSyntax(newArguments)
				)
				let functionCallTrimmed = "\(newFunctionCall)".trimmingCharacters(
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

			} else if let aw = condition.initializer?.value.as(AwaitExprSyntax.self),
				let functionCall = aw.expression.as(FunctionCallExprSyntax.self)
			{
				var newArguments = [LabeledExprSyntax]()
				for arg in functionCall.arguments {
					if let closureExpr = arg.expression.as(ClosureExprSyntax.self) {
						let processedClosure = processClosureExpr(closureExpr)
						newArguments.append(arg.with(\.expression, ExprSyntax(processedClosure)))
					} else {
						newArguments.append(arg)
					}
				}
				let newFunctionCall = functionCall.with(
					\.arguments,
					LabeledExprListSyntax(newArguments)
				)
				let functionCallTrimmed = "\(newFunctionCall)".trimmingCharacters(
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
			newItems.append(item)

		} else if let returnStmt = item.item.as(ReturnStmtSyntax.self),
			let functionCall = returnStmt.expression?.as(FunctionCallExprSyntax.self)
		{
			var newArguments = [LabeledExprSyntax]()
			for arg in functionCall.arguments {
				if let closureExpr = arg.expression.as(ClosureExprSyntax.self) {
					let processedClosure = processClosureExpr(closureExpr)
					newArguments.append(arg.with(\.expression, ExprSyntax(processedClosure)))
				} else {
					newArguments.append(arg)
				}
			}
			let newFunctionCall = functionCall.with(
				\.arguments,
				LabeledExprListSyntax(newArguments)
			)
			let newReturnStmt = returnStmt.with(\.expression, ExprSyntax(newFunctionCall))
			newItems.append(CodeBlockItemSyntax(item: .stmt(StmtSyntax(newReturnStmt))))
		} else {
			newItems.append(item)
		}
	}

	return CodeBlockItemListSyntax(newItems)
}

// func generateGuardStatement(
// 	condition: OptionalBindingConditionSyntax,
// 	functionCall: String,
// 	guardStmt: GuardStmtSyntax
// ) -> String {
// 	let pattern = condition.pattern.description
// 	let body = guardStmt.body.description.trimmingCharacters(in: .whitespacesAndNewlines)
// 	return """
// 		guard let \(pattern) = \(functionCall) else {
// 		    let err = ___err!
// 		    \(body)
// 		}
// 		"""
// }

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
		} else if let selfdecl = declaration as? InitializerDeclSyntax {
			if let body = selfdecl.body {
				return expandMacro(in: body.statements, file: "\(body)") + []
			}
		} else if let selfdecl = declaration as? ClosureExprSyntax {
			return expandMacro(in: selfdecl.statements, file: "\(selfdecl.statements)") + []

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
		} else if let selfdecl = declaration as? InitializerDeclSyntax {
			if let body = selfdecl.body {
				return expandMacro(in: body.statements, file: "\(body)", trace: true) + []
			}
		} else if let selfdecl = declaration as? ClosureExprSyntax {
			return expandMacro(in: selfdecl.statements, file: "\(selfdecl.statements)", trace: true)
				+ []

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
