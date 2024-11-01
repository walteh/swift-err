import Foundation
import SwiftCompilerPlugin
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder

class GuardVisitor: SyntaxRewriter {

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
			)
		else {
			return guardStmt  // No transformation if conditions don't match
		}

		var closureCaptureItems: [ClosureCaptureSyntax] = []
		var maybeTryExpr: TryExprSyntax? = nil
		var checkName = "___err___create"
		// if have no try, but have .get() then it's a Result and add a try
		if let fexpt = condition.initializer?.value.as(FunctionCallExprSyntax.self) {
			if let memberAccessExpr = fexpt.calledExpression.as(MemberAccessExprSyntax.self) {
				if memberAccessExpr.declName.baseName.text == "get" {
					maybeTryExpr = TryExprSyntax(
						tryKeyword: .keyword(.try),
						expression: ExprSyntax(fexpt)
					)
				}

			}
		} else if let tryExprd = condition.initializer?.value.as(TryExprSyntax.self) {
			if let awaitExpr = tryExprd.expression.as(AwaitExprSyntax.self) {
				if let declRefExpr = awaitExpr.expression.as(SubscriptCallExprSyntax.self) {
					maybeTryExpr = TryExprSyntax(
						tryKeyword: .keyword(.try),
						expression: ExprSyntax(
							AwaitExprSyntax(
								awaitKeyword: .keyword(.await),
								expression: ExprSyntax(declRefExpr.calledExpression)
							)
						)
					)
					for arg in declRefExpr.arguments {
						if let arg = arg.expression.as(DeclReferenceExprSyntax.self) {
							closureCaptureItems.append(
								ClosureCaptureSyntax(
									expression: arg
								)
							)
						}
					}
				} else {
					maybeTryExpr = TryExprSyntax(
						tryKeyword: .keyword(.try),
						expression: ExprSyntax(awaitExpr)
					)
				}

			} else {
				maybeTryExpr = tryExprd
			}
		} else if let awaitExpr = condition.initializer?.value.as(AwaitExprSyntax.self) {
			if let declRefExpr = awaitExpr.expression.as(SubscriptCallExprSyntax.self) {
				maybeTryExpr = TryExprSyntax(
					tryKeyword: .keyword(.try),
					expression: ExprSyntax(
						AwaitExprSyntax(
							awaitKeyword: .keyword(.await),
							expression: ExprSyntax(declRefExpr.calledExpression)
						)
					)
				)
				for arg in declRefExpr.arguments {
					if let arg = arg.expression.as(DeclReferenceExprSyntax.self) {
						closureCaptureItems.append(
							ClosureCaptureSyntax(
								expression: arg
							)
						)
					}
				}
			} else {
				maybeTryExpr = TryExprSyntax(
					tryKeyword: .keyword(.try),
					expression: ExprSyntax(awaitExpr)
				)
			}

		}

		guard let tryExpr = maybeTryExpr else {
			return guardStmt
		}

		let useAwait =
			tryExpr.expression.as(AwaitExprSyntax.self) != nil
		let expr = tryExpr.expression

		if useAwait {
			checkName = "___err___create___sendable"
		}

		let errString = "___err_\(getNextId())"
			.replacingOccurrences(of: "/", with: "_")
			.replacingOccurrences(of: ".", with: "_")

		// Create the closure with a proper signature to capture variables
		let catchingClosure = ClosureExprSyntax(
			leadingTrivia: nil,
			signature: closureCaptureItems.count > 0
				? ClosureSignatureSyntax(
					attributes: [],
					capture: ClosureCaptureClauseSyntax(
						leftSquare: .leftSquareToken(),
						items: ClosureCaptureListSyntax(
							closureCaptureItems
						),
						rightSquare: .rightSquareToken()
					),
					parameterClause: nil,
					effectSpecifiers: nil,
					returnClause: nil,
					inKeyword: .keyword(.in)
				) : nil,
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

				name: .identifier(checkName)
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
					name: .identifier(traced ? "___to___traced" : "___to")
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

		let letErrStatement = CodeBlockItemSyntax(
			item: .init(
				VariableDeclSyntax(
					bindingSpecifier: TokenSyntax.keyword(.let),
					bindings: PatternBindingListSyntax([
						PatternBindingSyntax(
							pattern: IdentifierPatternSyntax(identifier: .identifier("err")),

							initializer: InitializerClauseSyntax(
								equal: .equalToken(),
								value: ExprSyntax(
									ForceUnwrapExprSyntax(
										expression: ExprSyntax(
											DeclReferenceExprSyntax(
												baseName: .identifier(errString),
												argumentNames: nil
											)
										),
										exclamationMark: .exclamationMarkToken()
									)
								)
							)
						)
					])
				)
			)
		)
		let letNSErrStatement = CodeBlockItemSyntax(
			item: .init(
				VariableDeclSyntax(
					bindingSpecifier: TokenSyntax.keyword(.let),
					bindings: PatternBindingListSyntax([
						PatternBindingSyntax(
							pattern: IdentifierPatternSyntax(identifier: .identifier("nserr")),
							initializer: InitializerClauseSyntax(
								equal: .equalToken(),
								value: ExprSyntax(
									AsExprSyntax(
										expression: DeclReferenceExprSyntax(
											baseName: .identifier("err")
										),
										asKeyword: .keyword(.as),
										questionOrExclamationMark: .exclamationMarkToken(),
										type: IdentifierTypeSyntax(
											name: .identifier("NSError")
										)
									)
								)
							)
						)
					])
				)
			)
		)
		let letTErrStatement = CodeBlockItemSyntax(
			item: .init(
				VariableDeclSyntax(
					bindingSpecifier: TokenSyntax.keyword(.let),
					bindings: PatternBindingListSyntax([
						PatternBindingSyntax(
							pattern: IdentifierPatternSyntax(identifier: .identifier("terr")),
							initializer: InitializerClauseSyntax(
								equal: .equalToken(),
								value: ExprSyntax(
									AsExprSyntax(
										expression: DeclReferenceExprSyntax(
											baseName: .identifier("err")
										),
										asKeyword: .keyword(.as),
										questionOrExclamationMark: .exclamationMarkToken(),
										type: IdentifierTypeSyntax(
											name: .identifier("TError")
										)
									)
								)
							)
						)
					])
				)
			)
		)

		let usesErr = guardStmt.body.statements.contains { stmt in
			return stmt.description.contains("err")
		}

		let usesTErr = guardStmt.body.statements.contains { stmt in
			return stmt.description.contains("terr")
		}

		let usesNSErr = guardStmt.body.statements.contains { stmt in
			return stmt.description.contains("nserr")
		}

		// Step 7: Combine the new "let err = ___err!" statement with the original guard body statements
		let newBodyStatements =
			(usesErr || (usesTErr && traced) || usesNSErr
				? [letErrStatement]
				: [])
			+ (usesNSErr
				? [letNSErrStatement]
				: [])
			+ (usesTErr && traced
				? [letTErrStatement]
				: [])

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
