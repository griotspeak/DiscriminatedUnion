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
        let validatedExtractors = try instance.createTupleExtractors().map {
            try DeclSyntax(validating: $0)
        }

        let validatedPayloadExtractionError = try DeclSyntax(validating: extractorErrorDecl())

        return try [
            DeclSyntax(validating: "\(raw: discriminantDecl)"),
            validatedPropertyDecl,
            validatedPayloadExtractionError
        ] + validatedExtractors
    }

    enum Error: Swift.Error {
        case attemptPrint(String)
    }

    static func extractorErrorDecl() -> DeclSyntax {
        """
        public enum PayloadExtractionError: Swift.Error {
            case invalidExtraction(expected: Discriminant, actual: Discriminant)
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

    func createTupleExtractors() throws -> [DeclSyntax] {
        let theCases: [DeclSyntax] = childCases.compactMap { singleCase in
            TupleExtractionPropertyGenerator(singleCase: singleCase).generate()
        }

        return theCases
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

private struct TupleExtractionPropertyGenerator {
    let singleCase: EnumCaseElementSyntax

    func returnValue(parameterClause: EnumCaseParameterClauseSyntax) -> String {

        let rawOut = parameterClause.parameters.enumerated().map({ (index, parameter) in
            "\(parameter.firstName ?? "index\(raw: index)")"
        })

        if parameterClause.parameters.count == 1 {
            return rawOut.first!
        } else {
            return "(\(rawOut.joined(separator: ", ")))"
        }
    }

    func strippedParameters(parameterClause: EnumCaseParameterClauseSyntax) -> String {

        if parameterClause.parameters.count == 1 {
            return String(describing: parameterClause.parameters.first!.type)
        } else {
            return "(\(parameterClause.parameters.description))"
        }

    }

    func parameterBindings(parameterClause: EnumCaseParameterClauseSyntax) -> String {
        parameterClause
            .parameters
            .enumerated()
            .map{ (index, parameter) in
                "let \(parameter.firstName ?? "index\(raw: index)")"
            }.joined(separator: ", ")
    }

    func generate() -> DeclSyntax? {
        guard let parameterClause = singleCase.parameterClause else {
            return nil
        }

        let caseName = String(describing: singleCase.name)
        let tupleType = strippedParameters(parameterClause: parameterClause).replacingOccurrences(of: "@autoclosure ", with: "")
        let pBindings = parameterBindings(parameterClause: parameterClause)
        let titleCasedName = "\(caseName.first!.uppercased())\(caseName.dropFirst())"

        return """
            
            public static func tupleFrom\(raw: titleCasedName)(_ instance: Self) throws(PayloadExtractionError) -> \(raw: tupleType) {
                if case .\(raw: caseName)(\(raw: pBindings)) = instance {
                    return \(raw: returnValue(parameterClause: parameterClause))
                } else {
                    throw .invalidExtraction(expected: .\(raw: caseName), actual: instance.discriminant)
                }
            }
            
            """
    }
}
