Cheese = Struct.new(:id, :flavor, :fatContent, :source)
CHEESES = {
  1 => Cheese.new(1, "Brie", 0.19, 1),
  2 => Cheese.new(2, "Gouda", 0.3, 1),
  3 => Cheese.new(3, "Manchego", 0.065, "SHEEP")
}

Milk = Struct.new(:id, :fatContent, :source)
MILKS = {
  1 => Milk.new(1, 0.04, 1),
}
