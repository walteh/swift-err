import Foundation
import SwiftCompilerPlugin
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
@_spi(ExperimentalLanguageFeature) public import SwiftSyntaxMacros
import SwiftSyntaxMacros

class GuardStatementVisitor: SyntaxRewriter {

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

	private func transformGuardStatement(_ guardStmt: GuardStmtSyntax) -> GuardStmtSyntax {
		guard
			let condition = guardStmt.conditions.first?.condition.as(
				OptionalBindingConditionSyntax.self
			),
			let tryExpr = condition.initializer?.value.as(TryExprSyntax.self)
		else {
			return guardStmt  // No transformation if conditions don't match
		}

		let useAwait = tryExpr.expression.as(AwaitExprSyntax.self) != nil
		let expr = tryExpr.expression

		// let hash: String.SubSequence = "\(guardStmt.id.indexInTree.toOpaque())z".trimmingPrefix("-")

		let errString = "___err_\(getNextId())"
			.replacingOccurrences(of: "/", with: "_")
			.replacingOccurrences(of: ".", with: "_")

		// Create the transformed expression using syntax nodes
		let catchingClosure = ClosureExprSyntax.init(
			leadingTrivia: nil,
			// nil,
			statements: [
				.init(
					leadingTrivia: guardStmt.leadingTrivia + .tabs(1),
					item: .expr(
						ExprSyntax(
							TryExprSyntax(
								tryKeyword: .keyword(.try),
								expression: expr
							)
						)
					)
				)
			],
			rightBrace: .rightBraceToken(
				leadingTrivia: guardStmt.leadingTrivia.indentation(isOnNewline: false)!
			)
		)

		let createExpr = FunctionCallExprSyntax(
			calledExpression: MemberAccessExprSyntax(
				base: DeclReferenceExprSyntax(
					baseName: .identifier("Result")

				),

				name: .identifier("___err___create")
			),
			leftParen: .leftParenToken(),
			arguments: LabeledExprListSyntax([
				LabeledExprSyntax(
					label: "catching",
					colon: .colonToken(),
					expression: ExprSyntax(catchingClosure),
					trailingComma: nil
				)
			]),
			rightParen: .rightParenToken()
		)

		var toExpr: ExprSyntax = ExprSyntax(
			FunctionCallExprSyntax(
				calledExpression: MemberAccessExprSyntax(
					base: createExpr,
					name: .identifier(traced ? "___to_traced" : "___to")
				),
				leftParen: .leftParenToken(),
				arguments: LabeledExprListSyntax([
					LabeledExprSyntax(
						expression: ExprSyntax(
							InOutExprSyntax(
								ampersand: .prefixAmpersandToken(),
								expression: DeclReferenceExprSyntax(
									baseName: .identifier(errString)
								)
							)
						)
					)
				]),
				rightParen: .rightParenToken()
			)
		)

		if useAwait {
			toExpr = ExprSyntax(
				AwaitExprSyntax(
					awaitKeyword: .keyword(.await),
					expression: ExprSyntax(toExpr)
				)
			)
		}

		// Construct new initializer clause
		let newInitializer = InitializerClauseSyntax(
			equal: TokenSyntax.equalToken(),
			value: toExpr
		)

		// Construct new optional binding condition
		let newOptionalBinding = OptionalBindingConditionSyntax(
			bindingSpecifier: TokenSyntax.keyword(.let),
			pattern: condition.pattern,
			initializer: newInitializer
		)

		// Construct the new condition element list with the updated conditionthe
		let newConditionElement = ConditionElementSyntax(
			condition: .init(newOptionalBinding),
			trailingComma: nil
		)

		let newConditionList = ConditionElementListSyntax([newConditionElement])

		// Step 1: Create the forced unwrap expression "___err!"
		let forcedErrExpr = ForceUnwrapExprSyntax(
			expression: ExprSyntax(
				DeclReferenceExprSyntax(baseName: .identifier(errString), argumentNames: nil)
			),
			exclamationMark: .exclamationMarkToken()
		)

		// Step 2: Create the initializer clause " = ___err!"
		let initializerClause = InitializerClauseSyntax(
			equal: .equalToken(),
			value: ExprSyntax(forcedErrExpr)
		)

		// Step 3: Define the type annotation ": Error"
		let typeAnnotation = TypeAnnotationSyntax(
			colon: .colonToken(),
			type: IdentifierTypeSyntax(
				name: .identifier("Error"),
				genericArgumentClause: nil
			)
		)

		// Step 4: Create the pattern binding with "let err = ___err!"
		let patternBinding = PatternBindingSyntax(
			pattern: IdentifierPatternSyntax(identifier: .identifier("err")),
			typeAnnotation: typeAnnotation,
			initializer: initializerClause
		)

		// Step 5: Create the variable declaration "let err = ___err!"
		let letErrDeclaration = VariableDeclSyntax(
			bindingSpecifier: TokenSyntax.keyword(.let),
			bindings: PatternBindingListSyntax([patternBinding])
		)

		// Step 6: Wrap the variable declaration as a CodeBlockItemSyntax
		let letErrStatement = CodeBlockItemSyntax(item: .init(letErrDeclaration))

		// Step 7: Combine the new "let err = ___err!" statement with the original guard body statements
		let newBodyStatements =
			[letErrStatement]
			+ guardStmt.body.statements.map { stmt in
				return stmt
			}

		// Step 8: Create a new CodeBlockSyntax for the guard statement body
		let newBody = CodeBlockSyntax(
			leftBrace: guardStmt.body.leftBrace,
			statements: CodeBlockItemListSyntax(
				newBodyStatements.map { stmt in
					return
						stmt
						.with(\.leadingTrivia, guardStmt.leadingTrivia + [.tabs(1)])
				}
			),
			rightBrace: guardStmt.body.rightBrace
		)

		// The newBody can now be used in place of the original body in the guard statement
		let s = "\(guardStmt.guardKeyword)".replacingOccurrences(
			of: "guard",
			with: "var \(errString): Error? = nil; guard"
		)
		// Rebuild the guard statement with transformed condition and modified body
		return
			guardStmt
			.with(
				\.guardKeyword,
				"\(raw: s)"
			)
			.with(\.conditions, newConditionList)
			.with(\.body, newBody)

	}
}

@_spi(ExperimentalLanguageFeature)
public struct Err: BodyMacro {
	public static func expansion(
		of syn: AttributeSyntax,
		providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
		in ind: some MacroExpansionContext
	) throws -> [CodeBlockItemSyntax] {
		guard let body = declaration.body else { return [] }

		let visitor = GuardStatementVisitor(viewMode: .sourceAccurate)

		let result: CodeBlockSyntax = visitor.visit(body)

		// add an indentation to the result
		return [] + result.statements + []
	}
}

@_spi(ExperimentalLanguageFeature)
public struct ErrTraced: BodyMacro {
	public static func expansion(
		of _: AttributeSyntax,
		providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,

		in _: some MacroExpansionContext
	) throws -> [CodeBlockItemSyntax] {
		guard let body = declaration.body else { return [] }

		let visitor = GuardStatementVisitor(viewMode: .sourceAccurate)
		visitor.traced = true
		let result: CodeBlockSyntax = visitor.visit(body)

		// add an indentation to the result
		return [] + result.statements + []
	}
}

@main
struct ErrMacroPlugin: CompilerPlugin {
	let providingMacros: [Macro.Type] = [
		Err.self,
		ErrTraced.self,
	]
}
