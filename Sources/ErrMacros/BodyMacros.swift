import Foundation
import SwiftCompilerPlugin
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
@_spi(ExperimentalLanguageFeature) public import SwiftSyntaxMacros
import SwiftSyntaxMacros

@_spi(ExperimentalLanguageFeature)
public struct Err: BodyMacro {
	public static func expansion(
		of syn: AttributeSyntax,
		providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
		in ind: some MacroExpansionContext
	) throws -> [CodeBlockItemSyntax] {
		guard let body = declaration.body else { return [] }

		let visitor = GuardVisitor(viewMode: .sourceAccurate)

		let result: CodeBlockSyntax = visitor.visit(body)

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

		let visitor = GuardVisitor(viewMode: .sourceAccurate)
		visitor.traced = true
		let result: CodeBlockSyntax = visitor.visit(body)

		return [] + result.statements + []
	}
}
