import DiscriminatedUnion


@discriminatedUnion
enum Pet {
    case dog
    case cat(curious: Bool)
    case parrot(loud: Bool)
    case snake
    case turtle(snapper: Bool)
}

Swift.print("usiyan::: Pet.Discriminant.dog == Pet.dog.discriminant: \(String(describing: Pet.Discriminant.dog == Pet.dog.discriminant))")
