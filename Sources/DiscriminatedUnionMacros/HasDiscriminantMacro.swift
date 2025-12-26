//
//  HasDiscriminantMacro.swift
//  DiscriminatedUnion
//
//  Created by TJ Usiyan on 2025/12/26.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct HasDiscriminantMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        let arguments = node.arguments.map(\.expression)

        // TODO: properly handle this with diagnostics
        let requestedCases = arguments.dropFirst().map {
            """
            case \($0):
                return true
            """
        }.joined(separator: "\n")

        let switchWrittenOut: String =
        """
        switch \(node.arguments.first!.expression).discriminant {
        \(requestedCases)
        default:
            return false
        }
        """

        return
            """
            {
                \(raw: switchWrittenOut)
            }()
            """
    }
}
