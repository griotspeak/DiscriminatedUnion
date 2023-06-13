import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import DiscriminatedUnionMacros

let testMacros: [String: Macro.Type] = [
    "discriminatedUnion": DiscriminatedUnionMacro.self,
]

final class DiscriminatedUnionTests: XCTestCase {
    func testMacro() {
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

              enum Discriminant {
                case dog
                case cat
                case parrot
                case snake
              }
            }
            """,
            macros: testMacros
        )
    }
}


//func testMacro() {
//    assertMacroExpansion(
//        """
//        @DiscriminatedUnion
//        enum Pet {
//          case dog
//          case cat(curious: Bool)
//          case parrot
//          case snake
//        }
//        """,
//        expandedSource: """
//        enum Pet {
//          case dog
//          case cat(curious: Bool)
//          case parrot
//          case snake
//
//          enum Discriminant {
//            case dog
//            case cat
//            case parrot
//            case snake
//          }
//
//          var discriminant: Discriminant {
//            switch self {
//            case dog:
//                return .dog
//            case cat:
//                return .cat
//            case parrot:
//                return .parrot
//            case snake:
//                return .snake
//            }
//          }
//        }
//        """,
//        macros: testMacros
//    )
//}
