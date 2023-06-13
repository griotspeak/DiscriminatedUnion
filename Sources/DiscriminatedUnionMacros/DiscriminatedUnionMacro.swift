import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation

public struct DiscriminatedUnionMacro: MemberMacro {
    public static func expansion<Declaration, Context>(
        of node: SwiftSyntax.AttributeSyntax,
        providingMembersOf declaration: Declaration,
        in context: Context
    ) throws -> [SwiftSyntax.DeclSyntax]
    where
    Declaration : SwiftSyntax.DeclGroupSyntax,
    Context : SwiftSyntaxMacros.MacroExpansionContext {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            // TODO: Emit error
            return []
        }

        let members = enumDecl.memberBlock.members
        let caseDecls = members.compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
        let singleCases = caseDecls.flatMap { $0.elements }

        var discriminantDecl = try declareDiscriminant(singleCases: singleCases)
        discriminantDecl.memberBlock.rightBrace.leadingTrivia = .newline

        let unvalidatedPropertyDecl = try declareDiscriminantProperty(singleCases: singleCases)
        let validatedPropertyDecl = try DeclSyntax(validating: unvalidatedPropertyDecl)

        return try [
            DeclSyntax(validating: "\(raw: discriminantDecl)"),
            validatedPropertyDecl
        ]
    }

    enum Error: Swift.Error {
        case attemptPrint(String)
    }

    static func declareDiscriminant(singleCases: [EnumCaseElementListSyntax.Element]) throws -> EnumDeclSyntax {
        try EnumDeclSyntax("enum Discriminant") {
            for singleCase in singleCases {
                EnumCaseDeclSyntax(
                    leadingTrivia: .carriageReturn) {
                        EnumCaseElementSyntax(
                            leadingTrivia: .space,
                            identifier: singleCase.identifier)
                    }
            }
        }
    }

    static func declareDiscriminantProperty(singleCases: [EnumCaseElementListSyntax.Element]) throws -> DeclSyntax {
        let casesWrittenOut = singleCases.map {
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
