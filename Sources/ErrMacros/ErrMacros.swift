import Foundation
import SwiftCompilerPlugin
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
@_spi(ExperimentalLanguageFeature) public import SwiftSyntaxMacros
import SwiftSyntaxMacros

func buildGuardTransform(
	using tryExpr: TryExprSyntax,
	trace: Bool,
	toStatement: String
) -> String {
	let useAwait = tryExpr.expression.as(AwaitExprSyntax.self) != nil
	let expr = tryExpr.expression
	return
		"\(useAwait ? "await " : "")Result.___err___create(\(trace ? "tracing" : "catching"): {\ntry \(expr)\n}).\(toStatement)(&___err)"
}

// Define a custom visitor to collect Guard statements
class GuardStatementVisitor: SyntaxRewriter {
	override func visit(_ node: GuardStmtSyntax) -> StmtSyntax {
		// Transform the guard statement as needed
		let transformedGuardStmt = transformGuardStatement(node)

		// Return the modified guard statement
		return StmtSyntax(transformedGuardStmt)
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

		// Create the transformed expression string
		let transformedExpr =
			"\(useAwait ? "await " : "")Result.___err___create(catching: { try \(expr) }).___to(&___err)"

		// Construct new initializer clause
		let newInitializer = InitializerClauseSyntax(
			equal: TokenSyntax.equalToken(),
			value: ExprSyntax(
				DeclReferenceExprSyntax(
					identifier: .identifier(transformedExpr),
					declNameArguments: nil
				)
			)
		)

		// Construct new optional binding condition
		let newOptionalBinding = OptionalBindingConditionSyntax(
			bindingSpecifier: TokenSyntax.keyword(.let),
			pattern: condition.pattern,
			initializer: newInitializer
		)

		// Construct the new condition element list with the updated condition
		let newConditionElement = ConditionElementSyntax(
			condition: .init(newOptionalBinding),
			trailingComma: nil
		)

		let newConditionList = ConditionElementListSyntax([newConditionElement])

		// Rebuild the guard statement with transformed condition
		return
			guardStmt
			.with(\.conditions, newConditionList)
			.with(
				\.guardKeyword,
				// add comment before guard keyword
				TokenSyntax.init(
					stringLiteral: "var ___err: Error? = nil\n\(guardStmt.guardKeyword)"
				)
			)
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

		let result = GuardStatementVisitor(viewMode: .all).visit(body)

		return result.statements + []

	}
}

@_spi(ExperimentalLanguageFeature)
public struct ErrTraced: BodyMacro {
	public static func expansion(
		of _: AttributeSyntax,
		providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,

		in _: some MacroExpansionContext
	) throws -> [CodeBlockItemSyntax] {
		// if let selfdecl = declaration as? FunctionDeclSyntax {
		// 	if let body = selfdecl.body {
		// 		return expandMacro(in: body.statements, file: "\(body)", trace: true) + []
		// 	}
		// } else if let selfdecl = declaration as? InitializerDeclSyntax {
		// 	if let body = selfdecl.body {
		// 		return expandMacro(in: body.statements, file: "\(body)", trace: true) + []
		// 	}
		// } else if let selfdecl = declaration as? ClosureExprSyntax {
		// 	return expandMacro(in: selfdecl.statements, file: "\(selfdecl.statements)", trace: true)
		// 		+ []

		// }
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
