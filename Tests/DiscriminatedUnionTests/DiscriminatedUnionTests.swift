import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(DiscriminatedUnionMacros)
import DiscriminatedUnionMacros
let testMacros: [String: Macro.Type] = [
    "discriminatedUnion": DiscriminatedUnionMacro.self,
]
#endif

final class DiscriminatedUnionTests: XCTestCase {
    func testMacro() throws {
#if canImport(DiscriminatedUnionMacros)
        assertMacroExpansion(
            """
            @discriminatedUnion
            enum Pet {
              case dog
              case cat(curious: Bool)
              case parrot
              case snake
            }
            """,

            expandedSource: 
"""
enum Pet {
  case dog
  case cat(curious: Bool)
  case parrot
  case snake

    public enum Discriminant: DiscriminantType {
      case dog
      case cat
      case parrot
      case snake

    public var hasAssociatedType: Bool {
      switch self {
      case .dog:
          false // nil
      case .cat:
          true // Optional("curious: Bool")
      case .parrot:
          false // nil
      case .snake:
          false // nil
      }
    }
  }

  public var discriminant: Discriminant {
    switch self {
    case .dog:
      return .dog
    case .cat:
      return .cat
    case .parrot:
      return .parrot
    case .snake:
      return .snake
    }
  }
}

""",
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }
}
