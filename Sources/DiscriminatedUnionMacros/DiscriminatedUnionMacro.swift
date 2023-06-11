import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct DiscriminatedUnionMacro: MemberMacro {
    public static func expansion<Declaration, Context>(
        of node: SwiftSyntax.AttributeSyntax,
        providingMembersOf declaration: Declaration,
        in context: Context
    ) throws -> [SwiftSyntax.DeclSyntax]
    where
    Declaration : SwiftSyntax.DeclGroupSyntax,
    Context : SwiftSyntaxMacros.MacroExpansionContext {
        []
    }
}

@main
struct DiscriminatedUnionPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        DiscriminatedUnionMacro.self,
    ]
}
