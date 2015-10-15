Cheese = Struct.new(:id, :flavor, :fat_content, :source)
CHEESES = {
  1 => Cheese.new(1, "Brie", 0.19, 1),
  2 => Cheese.new(2, "Gouda", 0.3, 1),
  3 => Cheese.new(3, "Manchego", 0.065, "SHEEP")
}

Milk = Struct.new(:id, :fatContent, :source, :flavors)
MILKS = {
  1 => Milk.new(1, 0.04, 1, ["Natural", "Chocolate", "Strawberry"]),
}

DAIRY = OpenStruct.new(
  id: 1,
  cheese: CHEESES[1],
  milks: [MILKS[1]]
)

COW = OpenStruct.new(
  id: 1,
  name: 'Billy',
  last_produced_dairy: MILKS[1]
)
