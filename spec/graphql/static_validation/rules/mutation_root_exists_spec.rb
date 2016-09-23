require "spec_helper"

describe GraphQL::StaticValidation::MutationRootExists do
  let(:query_string) {%|
    mutation addBagel {
      introduceShip(input: {shipName: "Bagel"}) {
        clientMutationId
        shipEdge {
          node { name, id }
        }
      }
    }
  |}

  let(:schema) {
    query_root = GraphQL::Field.define do
      name "Query"
      description "Query root of the system"
    end

    GraphQL::Schema.define do
      query query_root
    end
  }

  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: schema, rules: [GraphQL::StaticValidation::MutationRootExists]) }
  let(:query) { GraphQL::Query.new(schema, query_string) }
  let(:errors) { validator.validate(query)[:errors] }

  it "errors when a mutation is performed on a schema without a mutation root" do
    assert_equal(1, errors.length)
    missing_mutation_root_error = {
      "message"=>"Schema is not configured for mutations",
      "locations"=>[{"line"=>2, "column"=>5}],
      "fields"=>["mutation addBagel"],
    }
    assert_includes(errors, missing_mutation_root_error)
  end
end
