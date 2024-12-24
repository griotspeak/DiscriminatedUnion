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
                case bird(name: String, Int)
            }
            """,

            expandedSource: 
"""
enum Pet {
    case dog
    case cat(curious: Bool)
    case parrot
    case snake
    case bird(name: String, Int)

    public enum Discriminant: DiscriminantType {
        case dog
        case cat
        case parrot
        case snake
        case bird

        public var hasAssociatedType: Bool {
            return switch self {
            case .dog:
                false // nil
            case .cat:
                true // Optional("curious: Bool")
            case .parrot:
                false // nil
            case .snake:
                false // nil
            case .bird:
                true // Optional("name: String, Int")
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
        case .bird:
            return .bird
        }
    }

    public enum ExtractorError: Swift.Error {
        case invalidExtraction(expected: Discriminant, actual: Discriminant)
    }

    public func catTupleValue() throws -> Bool {
        if case .cat(let curious) = self {
            return curious
        } else {
            throw ExtractorError.invalidExtraction(expected: .cat, actual: self.discriminant)
        }
    }

    public func birdTupleValue() throws -> (name: String, Int) {
        if case .bird(let name, let index1) = self {
            return (name, index1)
        } else {
            throw ExtractorError.invalidExtraction(expected: .bird, actual: self.discriminant)
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
