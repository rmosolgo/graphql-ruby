Cheese = Struct.new(:id, :flavor, :fat_content, :source)
CHEESES = {
  1 => Cheese.new(1, "Brie", 0.19, "COW"),
  2 => Cheese.new(2, "Gouda", 0.3, "COW"),
  3 => Cheese.new(3, "Manchego", 0.065, "SHEEP")
}
