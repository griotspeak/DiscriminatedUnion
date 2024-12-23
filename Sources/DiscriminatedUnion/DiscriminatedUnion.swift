
@attached(
    member,
    names: named(Discriminant), named(discriminant), prefixed(associatedValueFor)
)
@attached(extension, conformances: DiscriminatedUnion)
public macro discriminatedUnion() = #externalMacro(
    module: "DiscriminatedUnionMacros",
    type: "DiscriminatedUnionMacro")

public protocol DiscriminatedUnion {
    associatedtype Discriminant: DiscriminantType
    var discriminant: Discriminant { get }
}

public protocol DiscriminantType: Hashable, Equatable, CaseIterable {}

extension DiscriminatedUnion {
    public static func randomDiscriminant<G: RandomNumberGenerator>(
        using generator: inout G
    ) -> Self.Discriminant {
        Discriminant.random(using: &generator)
    }
}

extension DiscriminantType {
    public static func random<G: RandomNumberGenerator>(using generator: inout G) -> Self {
        Self.allCases.randomElement(using: &generator)!
    }

    public static func random() -> Self {
        var g = SystemRandomNumberGenerator()
        return Self.random(using: &g)
    }
}
