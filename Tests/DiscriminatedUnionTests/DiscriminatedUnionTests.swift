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
            @DiscriminatedUnion
            enum Pet {
              case dog
              case cat(curious: Bool)
              case parrot
              case snake
            }
            """,
            expandedSource: """
            @DiscriminatedUnion
            enum Pet {
              case dog
              case cat(curious: Bool)
              case parrot
              case snake

              enum Discriminant: Hashable {
                case dog
                case cat
                case parrot
                case snake
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
