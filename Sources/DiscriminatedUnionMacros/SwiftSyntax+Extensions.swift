//
//  File.swift
//  
//
//  Created by TJ Usiyan on 2023/6/13.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

extension DeclGroupSyntax {
    func descriptiveDeclKind(withArticle article: Bool = false) -> String {
        switch self {
        case is ActorDeclSyntax:
            return article ? "an actor" : "actor"
        case is ClassDeclSyntax:
            return article ? "a class" : "class"
        case is ExtensionDeclSyntax:
            return article ? "an extension" : "extension"
        case is ProtocolDeclSyntax:
            return article ? "a protocol" : "protocol"
        case is StructDeclSyntax:
            return article ? "a struct" : "struct"
        case is EnumDeclSyntax:
            return article ? "an enum" : "enum"
        default:
            fatalError("Unknown DeclGroupSyntax")
        }
    }
}

extension DeclModifierSyntax {
    var isNeededAccessLevelModifier: Bool {
        switch self.name.tokenKind {
        case .keyword(.public): return true
        default: return false
        }
    }
}

extension EnumDeclSyntax {
    var caseElements: [EnumCaseElementSyntax] {
        memberBlock.members.flatMap { member in
            guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
                return Array<EnumCaseElementSyntax>()
            }
            
            return Array(caseDecl.elements)
        }
    }
}

extension TokenSyntax {
    var initialUppercased: String {
        let name = self.text
        guard let initial = name.first else {
            return name
        }
        
        return "\(initial.uppercased())\(name.dropFirst())"
    }
}
