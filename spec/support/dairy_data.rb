Cheese = Struct.new(:id, :flavor, :origin, :fat_content, :source)
CHEESES = {
  1 => Cheese.new(1, "Brie", "France", 0.19, 1),
  2 => Cheese.new(2, "Gouda", "Netherlands", 0.3, 1),
  3 => Cheese.new(3, "Manchego", "Spain", 0.065, "SHEEP")
}

Milk = Struct.new(:id, :fatContent, :origin, :source, :flavors)
MILKS = {
  1 => Milk.new(1, 0.04, "Antiquity", 1, ["Natural", "Chocolate", "Strawberry"]),
}

DAIRY = OpenStruct.new(
  id: 1,
  cheese: CHEESES[1],
  milks: [MILKS[1]]
)

COW = OpenStruct.new(
  id: 1,
  name: "Billy",
  last_produced_dairy: MILKS[1]
)

POSTS = {
    1 => Acme::Post.new(1, "I"),
    2 => Acme::Post.new(2, "Like"),
    3 => Acme::Post.new(3, "Cheese")
}
