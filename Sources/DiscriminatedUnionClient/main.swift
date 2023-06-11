import DiscriminatedUnion


@DiscriminatedUnion
enum Pet {
  case dog
  case cat(curious: Bool)
  case parrot
  case snake
}


//Swift.print("usiyan::: Pet.dog.discriminant: \(String(describing: Pet.dog.discriminant))")
//print("The value \(result) was produced by the code \"\(code)\"")
