import Foundation
import SwiftCompilerPlugin
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
@_spi(ExperimentalLanguageFeature) public import SwiftSyntaxMacros
import SwiftSyntaxMacros

class DoGuardStatementVisitor: SyntaxRewriter {

	var traced: Bool = false

	override func visit(_ node: GuardStmtSyntax) -> StmtSyntax {
		// print("===== BEFORE =====")
		// print(node)

		// Transform the guard statement as needed
		let visitedNode = super.visit(node)
		guard let guardNode = visitedNode.as(GuardStmtSyntax.self) else {
			return StmtSyntax(visitedNode)
		}
		let transformedGuardStmt = transformGuardStatement(guardNode)
		let stmt = StmtSyntax(transformedGuardStmt)
		// print("===== AFTER =====")
		// print(stmt)
		// print("===== END =====")
		return stmt
	}

	private var uniqueCounter = 0

	private func getNextId() -> Int {
		uniqueCounter += 1
		return uniqueCounter
	}

	private func transformGuardStatement(_ guardStmt: GuardStmtSyntax) -> StmtSyntax {
		guard
			let condition = guardStmt.conditions.first?.condition.as(
				OptionalBindingConditionSyntax.self
			)
		else {
			return StmtSyntax(guardStmt)
		}

		print(guardStmt.debugDescription)

		// Extract the pattern (variable name) and expression
		let pattern = condition.pattern
		let expr = condition.initializer?.value

		// Create the do-catch block
		let doStmt = DoStmtSyntax(
			doKeyword: .keyword(.do).with(\.leadingTrivia, .spaces(1)),
			body: CodeBlockSyntax(
				statements: CodeBlockItemListSyntax([
					CodeBlockItemSyntax(
						item: .stmt(
							StmtSyntax(
								ExpressionStmtSyntax(
									expression: SequenceExprSyntax(
										elements: ExprListSyntax([
											ExprSyntax(
												DeclReferenceExprSyntax(
													baseName: .identifier(pattern.description)
												)
											),
											ExprSyntax(
												AssignmentExprSyntax(
													equal: .equalToken()
												)
											),
											expr!,
										])
									)
								)
							)
						)
					)
				])
			),
			catchClauses: CatchClauseListSyntax([
				CatchClauseSyntax(
					catchKeyword: .keyword(.catch),
					catchItems: [],
					body: guardStmt.body
				)
			])
		)

		return StmtSyntax(doStmt)
	}
}

@_spi(ExperimentalLanguageFeature)
public struct DoErr: BodyMacro {
	public static func expansion(
		of syn: AttributeSyntax,
		providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
		in ind: some MacroExpansionContext
	) throws -> [CodeBlockItemSyntax] {
		guard let body = declaration.body else { return [] }

		let visitor = DoGuardStatementVisitor(viewMode: .sourceAccurate)

		let result: CodeBlockSyntax = visitor.visit(body)

		// add an indentation to the result
		return [] + result.statements + []
	}
}

@_spi(ExperimentalLanguageFeature)
public struct DoErrTraced: BodyMacro {
	public static func expansion(
		of _: AttributeSyntax,
		providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,

		in _: some MacroExpansionContext
	) throws -> [CodeBlockItemSyntax] {
		guard let body = declaration.body else { return [] }

		let visitor = DoGuardStatementVisitor(viewMode: .sourceAccurate)
		visitor.traced = true
		let result: CodeBlockSyntax = visitor.visit(body)

		// add an indentation to the result
		return [] + result.statements + []
	}
}
