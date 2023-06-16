//
//  CaseMacroDiagnostic.swift
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

enum CaseMacroDiagnostic {
  case notAnEnum(DeclGroupSyntax)
}

extension CaseMacroDiagnostic: DiagnosticMessage {
  var message: String {
    switch self {
    case .notAnEnum(let decl):
      return "'@MetaEnum' can only be attached to an enum, not \(decl.descriptiveDeclKind(withArticle: true))"
    }
  }

  var diagnosticID: MessageID {
    switch self {
    case .notAnEnum:
      return MessageID(domain: "MetaEnumDiagnostic", id: "notAnEnum")
    }
  }

  var severity: DiagnosticSeverity {
    switch self {
    case .notAnEnum:
      return .error
    }
  }

  func diagnose(at node: Syntax) -> Diagnostic {
    Diagnostic(node: node, message: self)
  }
}
