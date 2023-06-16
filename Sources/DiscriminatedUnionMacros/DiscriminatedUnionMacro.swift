import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

public struct DiscriminatedUnionMacro {

    // cribbed from MetaEnum
    let parentTypeName: TokenSyntax
    let childCases: [EnumCaseElementSyntax]
    let access: ModifierListSyntax.Element?
    let parentParamName: TokenSyntax

    init(
        node: AttributeSyntax,
        declaration: some DeclGroupSyntax,
        context: some MacroExpansionContext
    ) throws {
      guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
        throw DiagnosticsError(diagnostics: [
          CaseMacroDiagnostic.notAnEnum(declaration).diagnose(at: Syntax(node))
        ])
      }

      parentTypeName = enumDecl.identifier.with(\.trailingTrivia, [])

      access = enumDecl.modifiers?.first(where: \.isNeededAccessLevelModifier)

      childCases = enumDecl.caseElements.map { parentCase in
        parentCase.with(\.associatedValue, nil)
      }

      parentParamName = context.makeUniqueName("parent")
    }
}

extension DiscriminatedUnionMacro: MemberMacro {
    public static func expansion<Declaration, Context>(
        of node: SwiftSyntax.AttributeSyntax,
        providingMembersOf declaration: Declaration,
        in context: Context
    ) throws -> [SwiftSyntax.DeclSyntax]
    where
    Declaration : SwiftSyntax.DeclGroupSyntax,
    Context : SwiftSyntaxMacros.MacroExpansionContext {
        let instance = try DiscriminatedUnionMacro(
            node: node,
            declaration: declaration,
            context: context)

        var discriminantDecl = try instance.declareDiscriminant()
        discriminantDecl.memberBlock.rightBrace.leadingTrivia = .newline

        let unvalidatedPropertyDecl = try instance.declareDiscriminantProperty()
        let validatedPropertyDecl = try DeclSyntax(validating: unvalidatedPropertyDecl)

        return try [
            DeclSyntax(validating: "\(raw: discriminantDecl)"),
            validatedPropertyDecl
        ]
    }

    enum Error: Swift.Error {
        case attemptPrint(String)
    }

    func declareDiscriminant() throws -> EnumDeclSyntax {
        try EnumDeclSyntax("enum Discriminant: Hashable") {
            for singleCase in childCases {
                EnumCaseDeclSyntax(
                    leadingTrivia: .carriageReturn) {
                        EnumCaseElementSyntax(
                            leadingTrivia: .space,
                            identifier: singleCase.identifier)
                    }
            }
        }
    }

    func declareDiscriminantProperty() throws -> DeclSyntax {
        let casesWrittenOut = childCases.map {
                """
                case .\($0.identifier):
                    return .\($0.identifier)
                """
        }.joined(separator: "\n")

        let switchWrittenOut: DeclSyntax =
        """
        switch self {
        \(raw: casesWrittenOut)
        }
        """

        return
            """
            var discriminant: Discriminant {
                \(switchWrittenOut)
            }
            """

    }

}


@main
struct DiscriminatedUnionPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        DiscriminatedUnionMacro.self,
    ]
}

