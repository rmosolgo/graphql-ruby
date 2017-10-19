# frozen_string_literal: true

# Here's the "application"
module Jazz
  # Here's a new-style GraphQL type definition
  class Ensemble < GraphQL::Object
    description "A group of musicians playing together"
    field :name, "String", null: false
    field :musicians, "[Jazz::Musician]", null: false
  end

  # Lives side-by-side with an old-style definition
  InstrumentType = GraphQL::ObjectType.define do
    name "Instrument"
    field :name, !types.String
  end

  class Musician < GraphQL::Object
    description "Someone who plays an instrument"
    field :name, String, null: false
    field :instrument, InstrumentType, null: false
  end

  # Another new-style definition, with method overrides
  class Query < GraphQL::Object
    field :ensembles, [Ensemble]
    field :instruments, [InstrumentType]

    def ensembles
      [OpenStruct.new(name: "Bela Fleck and the Flecktones")]
    end

    def instruments
      [OpenStruct.new(name: "banjo")]
    end
  end

  # New-style Schema definition
  class Schema < GraphQL::Schema
    query(Query)
  end
end
