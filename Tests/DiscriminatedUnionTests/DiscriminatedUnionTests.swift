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
                case hydra(@autoclosure () -> String, String)
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
    case hydra(@autoclosure () -> String, String)

    public enum Discriminant: DiscriminantType {
        case dog
        case cat
        case parrot
        case snake
        case bird
        case hydra

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
            case .hydra:
                true // Optional("@autoclosure () -> String, String")
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
        case .hydra:
            return .hydra
        }
    }

    public enum PayloadExtractionError: Swift.Error {
        case invalidExtraction(expected: Discriminant, actual: Discriminant)
    }

    public static func tupleFromCat(_ instance: Self) -> Swift.Result<Bool, PayloadExtractionError> {
        if case .cat(let curious) = instance {
            .success(curious)
        } else {
            .failure(.invalidExtraction(expected: .cat, actual: instance.discriminant))
        }
    }

    public static func tupleFromBird(_ instance: Self) -> Swift.Result<(name: String, Int), PayloadExtractionError> {
        if case .bird(let name, let index1) = instance {
            .success((name, index1))
        } else {
            .failure(.invalidExtraction(expected: .bird, actual: instance.discriminant))
        }
    }

    public static func tupleFromHydra(_ instance: Self) -> Swift.Result<(() -> String, String), PayloadExtractionError> {
        if case .hydra(let index0, let index1) = instance {
            .success((index0, index1))
        } else {
            .failure(.invalidExtraction(expected: .hydra, actual: instance.discriminant))
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
