import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(DiscriminatedUnionMacros)
import DiscriminatedUnionMacros
@MainActor let testMacros: [String: Macro.Type] = [
    "discriminatedUnion": DiscriminatedUnionMacro.self,
    "hasDiscriminant": HasDiscriminantMacro.self
]
#endif

final class DiscriminatedUnionTests: XCTestCase {
    @MainActor func testDiscriminatedUnionMacro() throws {
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

    public func hasDiscriminant(in acceptableOptions: Set<Discriminant>) -> Bool {
        acceptableOptions.contains(discriminant)
    }

    // MARK: Payload Extraction

    public enum PayloadExtractionError: Swift.Error {
        case invalidExtraction(expected: Discriminant, actual: Discriminant)
    }

    public static func tupleFromCat(_ instance: Self) throws(PayloadExtractionError) -> Bool {
        if case .cat(let curious) = instance {
            return curious
        } else {
            throw .invalidExtraction(expected: .cat, actual: instance.discriminant)
        }
    }

    public static func tupleFromBird(_ instance: Self) throws(PayloadExtractionError) -> (name: String, Int) {
        if case .bird(let name, let index1) = instance {
            return (name, index1)
        } else {
            throw .invalidExtraction(expected: .bird, actual: instance.discriminant)
        }
    }

    public static func tupleFromHydra(_ instance: Self) throws(PayloadExtractionError) -> (() -> String, String) {
        if case .hydra(let index0, let index1) = instance {
            return (index0, index1)
        } else {
            throw .invalidExtraction(expected: .hydra, actual: instance.discriminant)
        }
    }

    // MARK: IsCase Properties

    public var isDog: Bool {
        discriminant == .dog
    }

    public var isCat: Bool {
        discriminant == .cat
    }

    public var isParrot: Bool {
        discriminant == .parrot
    }

    public var isSnake: Bool {
        discriminant == .snake
    }

    public var isBird: Bool {
        discriminant == .bird
    }

    public var isHydra: Bool {
        discriminant == .hydra
    }
}

""",
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

    @MainActor func testHasDiscriminantMacro() throws {
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
            
            let variable = Pet.parrot
            #hasDiscriminant(variable, in: .dog, .snake
            )
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

    public func hasDiscriminant(in acceptableOptions: Set<Discriminant>) -> Bool {
        acceptableOptions.contains(discriminant)
    }

    // MARK: Payload Extraction

    public enum PayloadExtractionError: Swift.Error {
        case invalidExtraction(expected: Discriminant, actual: Discriminant)
    }

    public static func tupleFromCat(_ instance: Self) throws(PayloadExtractionError) -> Bool {
        if case .cat(let curious) = instance {
            return curious
        } else {
            throw .invalidExtraction(expected: .cat, actual: instance.discriminant)
        }
    }

    public static func tupleFromBird(_ instance: Self) throws(PayloadExtractionError) -> (name: String, Int) {
        if case .bird(let name, let index1) = instance {
            return (name, index1)
        } else {
            throw .invalidExtraction(expected: .bird, actual: instance.discriminant)
        }
    }

    public static func tupleFromHydra(_ instance: Self) throws(PayloadExtractionError) -> (() -> String, String) {
        if case .hydra(let index0, let index1) = instance {
            return (index0, index1)
        } else {
            throw .invalidExtraction(expected: .hydra, actual: instance.discriminant)
        }
    }

    // MARK: IsCase Properties

    public var isDog: Bool {
        discriminant == .dog
    }

    public var isCat: Bool {
        discriminant == .cat
    }

    public var isParrot: Bool {
        discriminant == .parrot
    }

    public var isSnake: Bool {
        discriminant == .snake
    }

    public var isBird: Bool {
        discriminant == .bird
    }

    public var isHydra: Bool {
        discriminant == .hydra
    }
}

let variable = Pet.parrot
{
    switch variable.discriminant {
    case .dog:
        return true
    case .snake:
        return true
    default:
        return false
    }
}()
""",
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }
}
