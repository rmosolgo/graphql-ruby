module Jazz
  class Ensemble < GraphQL::Object
    description "A group of musicians playing together"
    field :name, "String", null: false
  end

  class Query < GraphQL::Object
    field :ensembles, [Ensemble]

    def ensembles
      [
        OpenStruct.new(name: "Bela Fleck and the Flecktones"),
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
