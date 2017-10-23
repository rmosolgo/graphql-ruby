# frozen_string_literal: true
require 'ostruct'
module Dummy
  Cheese = Struct.new(:id, :flavor, :origin, :fat_content, :source) do
    def ==(other)
      # This is buggy on purpose -- it shouldn't be called during execution.
      other.id == id
    end

    # Alias for when this is treated as milk in EdibleAsMilkInterface
    def fatContent # rubocop:disable Naming/MethodName
      fat_content
    end
  end

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

  Cow = Struct.new(:id, :name, :last_produced_dairy)
  COWS = {
    1 => Cow.new(1, "Billy", MILKS[1])
  }

  Goat = Struct.new(:id, :name, :last_produced_dairy)
  GOATS = {
    1 => Goat.new(1, "Gilly", MILKS[1]),
  }
end
