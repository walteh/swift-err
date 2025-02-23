import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

@_spi(ExperimentalLanguageFeature)
public struct ErrSimple: BodyMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
        in context: some MacroExpansionContext
    ) throws -> [CodeBlockItemSyntax] {
        guard let body = declaration.body else { return [] }

        let visitor = SimpleGuardVisitor(viewMode: .sourceAccurate)
        let result: CodeBlockSyntax = visitor.visit(body)

        return Array(result.statements)
    }
}

fileprivate enum SimpleErrDiagnostic: DiagnosticMessage {
    case expansion(String)

    var severity: DiagnosticSeverity { .note }

    var message: String {
        switch self {
        case .expansion(let expanded):
            return "Expanded to:\n\(expanded)"
        }
    }

    var diagnosticID: MessageID {
        .init(domain: "SimpleErr", id: "expansion")
    }
}

class SimpleGuardVisitor: SyntaxRewriter {
    private var uniqueCounter = 0
    private var indentationLevel = 1
    private var inClosure = false

    private func getNextId() -> Int {
        uniqueCounter += 1
        return uniqueCounter
    }

    override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
        let oldInClosure = inClosure
        inClosure = true
        defer { inClosure = oldInClosure }
        return super.visit(node)
    }

    override func visit(_ node: GuardStmtSyntax) -> StmtSyntax {
        // Skip transformation for guards inside closures
        if inClosure {
            return StmtSyntax(node)
        }

        guard let condition = node.conditions.first?.condition.as(OptionalBindingConditionSyntax.self) else {
            return StmtSyntax(node)
        }

        let errId = "err__\(getNextId())"
        let pattern = condition.pattern
        let initializer = condition.initializer?.value

        // Create the error variable declaration
        let errVarDecl = "var \(errId): Error? = nil; "

        // Preserve the original try/await structure
        let newValue: ExprSyntax
        if let tryExpr = initializer?.as(TryExprSyntax.self) {
            if let awaitExpr = tryExpr.expression.as(AwaitExprSyntax.self) {
                // try await case
                newValue = ExprSyntax(
                    TryExprSyntax(
                        tryKeyword: .keyword(.try),
                        expression: AwaitExprSyntax(
                            awaitKeyword: .keyword(.await),
                            expression: ExprSyntax(
                                InfixOperatorExprSyntax(
                                    leftOperand: awaitExpr.expression,
                                    operator: BinaryOperatorExprSyntax(
                                        operator: .binaryOperator("~>")
                                    ),
                                    rightOperand: ExprSyntax(
                                        DeclReferenceExprSyntax(baseName: .identifier(errId))
                                    )
                                )
                            )
                        )
                    )
                )
            } else {
                // try case (sync)
                newValue = ExprSyntax(
                    TryExprSyntax(
                        tryKeyword: .keyword(.try),
                        expression: ExprSyntax(
                            InfixOperatorExprSyntax(
                                leftOperand: tryExpr.expression,
                                operator: BinaryOperatorExprSyntax(
                                    operator: .binaryOperator("??")
                                ),
                                rightOperand: ExprSyntax(
                                    DeclReferenceExprSyntax(baseName: .identifier(errId))
                                )
                            )
                        )
                    )
                )
            }
        } else {
            // plain case
            newValue = ExprSyntax(
                InfixOperatorExprSyntax(
                    leftOperand: initializer ?? ExprSyntax(stringLiteral: ""),
                    operator: BinaryOperatorExprSyntax(
                        operator: .binaryOperator("??")
                    ),
                    rightOperand: ExprSyntax(
                        DeclReferenceExprSyntax(baseName: .identifier(errId))
                    )
                )
            )
        }

        let newInitializer = InitializerClauseSyntax(
            equal: .equalToken(),
            value: newValue
        )

        let newBinding = OptionalBindingConditionSyntax(
            bindingSpecifier: .keyword(.let),
            pattern: pattern,
            initializer: newInitializer
        )

        let newConditions = ConditionElementListSyntax([
            ConditionElementSyntax(
                condition: .init(newBinding),
                trailingComma: nil
            )
        ])

        // Create the error unwrapping statement with proper indentation
        let errUnwrapStmt = CodeBlockItemSyntax(
            leadingTrivia: .tabs(indentationLevel),
            item: .init(
                VariableDeclSyntax(
                    bindingSpecifier: .keyword(.let),
                    bindings: PatternBindingListSyntax([
                        PatternBindingSyntax(
                            pattern: IdentifierPatternSyntax(identifier: .identifier("err")),
                            initializer: InitializerClauseSyntax(
                                equal: .equalToken(),
                                value: ExprSyntax(
                                    ForceUnwrapExprSyntax(
                                        expression: DeclReferenceExprSyntax(baseName: .identifier(errId)),
                                        exclamationMark: .exclamationMarkToken()
                                    )
                                )
                            )
                        )
                    ])
                )
            )
        )

        // Create the new body with proper indentation
        var statements = node.body.statements
        for i in statements.indices {
            statements[i] = statements[i].with(\.leadingTrivia, .tabs(indentationLevel))
        }

        let newStatements = CodeBlockItemListSyntax {
            errUnwrapStmt
            statements
        }

        let newBody = CodeBlockSyntax(
            leftBrace: node.body.leftBrace,
            statements: newStatements,
            rightBrace: node.body.rightBrace.with(\.leadingTrivia, .tabs(indentationLevel))
        )

        // Create the new guard statement with proper indentation
        let newGuard = node
            .with(\.leadingTrivia, .tabs(indentationLevel))
            .with(\.guardKeyword, "\(raw: errVarDecl)guard")
            .with(\.conditions, newConditions)
            .with(\.body, newBody)

        return StmtSyntax(newGuard)
    }
}
