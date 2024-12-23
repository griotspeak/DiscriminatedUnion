import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

public struct DiscriminatedUnionMacro {

    // cribbed from MetaEnum example that seems to have disappeared.
    let parentTypeName: TokenSyntax
    let childCases: [EnumCaseElementSyntax]
    let access: DeclModifierListSyntax.Element?
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

        parentTypeName = enumDecl.name.with(\.trailingTrivia, [])

        access = enumDecl.modifiers.first(where: \.isNeededAccessLevelModifier)

        childCases = enumDecl.caseElements

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

        var discriminantDecl = try instance.declareDiscriminantType()
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

    func declareDiscriminantType() throws -> EnumDeclSyntax {
        try EnumDeclSyntax("public enum Discriminant: DiscriminantType") {
            for singleCase in childCases {
                EnumCaseDeclSyntax(
                    leadingTrivia: .newline) {
                        EnumCaseElementSyntax(
                            leadingTrivia: .space,
                            name: singleCase.name)
                    }
            }

            "\n"
            "\n"

            try declareHasAssociatedTypeFunction()
        }
    }

    func declareHasAssociatedTypeFunction() throws -> DeclSyntax {
        let theCases = childCases.map { singleCase in
            let myTrivia = singleCase.parameterClause?.parameters.description
            return "case .\(singleCase.name): \(singleCase.parameterClause != nil) // \(String(describing: myTrivia))"
        }
        let theSwitch = """
        return switch self {
        \(theCases.joined(separator: "\n"))
        }
        """
        return DeclSyntax(stringLiteral:"""

            
            public var hasAssociatedType: Bool {
                \(theSwitch)
            }
            """
        )
    }

    func declareDiscriminantProperty() throws -> DeclSyntax {
        let casesWrittenOut = childCases.map {
                """
                case .\($0.name):
                    return .\($0.name)
                """
        }.joined(separator: "\n")

        let switchWrittenOut: String =
        """
        switch self {
        \(casesWrittenOut)
        }
        """

        return
            """
            public var discriminant: Discriminant {
                \(raw: switchWrittenOut)
            }
            """

    }

}

extension DiscriminatedUnionMacro: ExtensionMacro {
  public static func expansion(
    of attribute: AttributeSyntax,
    attachedTo decl: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    // If there is an explicit conformance to DiscriminatedUnion already, don't add one.
    if protocols.isEmpty {
      return []
    }

    let ext: DeclSyntax =
      """
      extension \(type.trimmed): DiscriminatedUnion {}
      """

    return [ext.cast(ExtensionDeclSyntax.self)]
  }
}


@main
struct DiscriminatedUnionPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        DiscriminatedUnionMacro.self,
    ]
}

