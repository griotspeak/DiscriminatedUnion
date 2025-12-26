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

        let requestedCases = arguments.map {
            """
            case \($0):
                return true
            """
        }.joined(separator: "\n")

        let switchWrittenOut: String =
        """
        switch self {
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
