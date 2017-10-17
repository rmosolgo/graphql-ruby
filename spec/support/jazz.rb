# frozen_string_literal: true
module Jazz
  module Models
    Ensemble = Struct.new(:name)
  end

  class Ensemble < GraphQL::Object
    model Models::Ensemble
    description "A group of musicians playing together"
    field :name, "String", null: false
  end

  class Query < GraphQL::Object
    field :ensembles, "[Ensemble]"

    def ensembles
      [
        Models::Ensemble.new("Bela Fleck and the Flecktones"),
      ]
    end
  end

  class Schema < GraphQL::Schema
    query(Query)
    namespace(Jazz)
  end

  # Prep the schema
  Schema.boot
end
