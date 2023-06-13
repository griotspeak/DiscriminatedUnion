
@attached(
    member,
    names: named(Discriminant), named(discriminant)
)
public macro DiscriminatedUnion() = #externalMacro(
    module: "DiscriminatedUnionMacros",
    type: "DiscriminatedUnionMacro")
