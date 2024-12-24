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
        conformingTo protocols: [TypeSyntax],
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
        let validatedExtractors = try instance.doSomethingSpecial().map {
            try DeclSyntax(validating: $0)
        }

        let validatedExtractorError = try DeclSyntax(validating: extractorErrorDecl())

        return try [
            DeclSyntax(validating: "\(raw: discriminantDecl)"),
            validatedPropertyDecl,
            validatedExtractorError
        ] + validatedExtractors
    }

    enum Error: Swift.Error {
        case attemptPrint(String)
    }

    static func extractorErrorDecl() -> DeclSyntax {
        """
        public enum ExtractorError: Swift.Error {
            case invalidExtraction
        }
        """
    }

    func declareDiscriminantType() throws -> EnumDeclSyntax {
        return try EnumDeclSyntax("public enum Discriminant: DiscriminantType") {

            for singleCase in childCases {
                EnumCaseDeclSyntax(
                    leadingTrivia: .newline) {
                        EnumCaseElementSyntax(
                            leadingTrivia: .space,
                            name: singleCase.name)
                    }
            }

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

    func doSomethingSpecial() throws -> [DeclSyntax] {
        let theCases = childCases.compactMap { singleCase in
            if let parameterClause = singleCase.parameterClause {
                let bindings = parameterClause.parameters.enumerated().map({ (index, parameter) in
                    "let \(parameter.firstName ?? "index\(raw: index)")"
                })

                let rawOut = parameterClause.parameters.enumerated().map({ (index, parameter) in
                    "\(parameter.firstName ?? "index\(raw: index)")"
                })

                let output: String
                if parameterClause.parameters.count == 1 {
                    output = rawOut.first!
                } else {
                    output = "(\(rawOut.joined(separator: ", ")))"
                }

                return (
                    String(describing: singleCase.name),
                    parameterClause.parameters.count == 1 ? String(describing: parameterClause.parameters.first!.type) : "(\(parameterClause.parameters.description))",
                    bindings.joined(separator: ", "),
                    output
                )
            } else {
                return nil
            }
        }

        let theSomethings: [DeclSyntax] = theCases.map { caseName, tupleType, pBindings, returnValue in
//            let titleCasedName = "\(caseName.first!.uppercased())\(caseName.dropFirst())"
            return """

            public func \(raw: caseName)AssociatedValue() throws -> \(raw: tupleType) {
                if case .\(raw: caseName)(\(raw: pBindings)) = self {
                    return \(raw: returnValue)
                } else {
                    throw ExtractorError.invalidExtraction
                }
            }

            """
        }

        Swift.print("usiyan::: theSomethings: \(String(describing: theSomethings))")
        return theSomethings
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

