# frozen_string_literal: true

# Here's the "application"
module Jazz
  INSTRUMENTS = [
    OpenStruct.new(name: "Banjo", family: :str),
    OpenStruct.new(name: "Flute", family: "WOODWIND"),
    OpenStruct.new(name: "Trumpet", family: "BRASS"),
    OpenStruct.new(name: "Piano", family: "KEYS"),
    OpenStruct.new(name: "Organ", family: "KEYS"),
    OpenStruct.new(name: "Drum Kit", family: "PERCUSSION"),
  ]

  # Here's a new-style GraphQL type definition
  class Ensemble < GraphQL::Object
    description "A group of musicians playing together"
    field :name, "String", null: false
    field :musicians, "[Jazz::Musician]", null: false
  end

  class Family < GraphQL::Enum
    description "Groups of musical instruments"
    # support string and symbol
    value "STRING", "Makes a sound by vibrating strings", value: :str
    value :WOODWIND, "Makes a sound by vibrating air in a pipe"
    value :BRASS, "Makes a sound by amplifying the sound of buzzing lips"
    value "PERCUSSION", "Makes a sound by hitting something that vibrates"
    value "KEYS", "Neither here nor there, really"
    value "DIDGERIDOO", "Makes a sound by amplifying the sound of buzzing lips", deprecation_reason: "Merged into BRASS"
  end

  # Lives side-by-side with an old-style definition
  InstrumentType = GraphQL::ObjectType.define do
    name "Instrument"
    field :name, !types.String
    field :family, Family.to_graphql.to_non_null_type
  end

  class Musician < GraphQL::Object
    description "Someone who plays an instrument"
    field :name, String, null: false
    field :instrument, InstrumentType, null: false
  end

  # Another new-style definition, with method overrides
  class Query < GraphQL::Object
    field :ensembles, [Ensemble], null: false
    field :instruments, [InstrumentType], null: false do
      argument :family, Family, null: true
    end

    def ensembles
      [OpenStruct.new(name: "Bela Fleck and the Flecktones")]
    end

    def instruments(family: nil)
      if family
        INSTRUMENTS.select { |i| i.family == family }
      else
        INSTRUMENTS
      end
    end
  end

  # New-style Schema definition
  class Schema < GraphQL::Schema
    query(Query)
  end
end
