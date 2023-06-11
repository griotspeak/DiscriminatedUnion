
@attached(
    member,
    names:
        named(Discriminant))
public macro DiscriminatedUnion() = #externalMacro(
    module: "DiscriminatedUnionMacros",
    type: "DiscriminatedUnionMacro")
