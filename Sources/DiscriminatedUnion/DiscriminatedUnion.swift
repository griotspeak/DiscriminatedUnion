
@attached(
    member,
    names: named(Discriminant), named(discriminant)
)
@attached(extension, conformances: DiscriminatedUnion)
public macro DiscriminatedUnion() = #externalMacro(
    module: "DiscriminatedUnionMacros",
    type: "DiscriminatedUnionMacro")

public protocol DiscriminatedUnion {
    associatedtype Discriminant: Hashable, Equatable, CaseIterable
    var discriminant: Discriminant { get }
}
