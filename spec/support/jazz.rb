# frozen_string_literal: true

# Here's the "application"
module Jazz
  # Here are some classes that the application deals with
  module Models
    Ensemble = Struct.new(:name)
    Instrument = Struct.new(:name)
  end

  # Here's a new-style GraphQL type definition
  class Ensemble < GraphQL::Object
    model Models::Ensemble
    description "A group of musicians playing together"
    field :name, "String", null: false
  end

  # Lives side-by-side with an old-style definition
  InstrumentType = GraphQL::ObjectType.define do
    name "Instrument"
    field :name, !types.String
  end

  # Another new-style definition, with method overrides
  class Query < GraphQL::Object
    field :ensembles, "[Ensemble]"
    field :instruments, "[Instrument]"

    def ensembles
      [Models::Ensemble.new("Bela Fleck and the Flecktones")]
    end

    def instruments
      [Models::Instrument.new("banjo")]
    end
  end

  # New-style Schema definition
  class Schema < GraphQL::Schema
    query(Query)
    namespace(Jazz)
  end

  # Prep the schema, now a required step,
  # but can be rebooted during Rails development
  Schema.boot
end
