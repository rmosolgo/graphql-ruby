require "spec_helper"

describe GraphQL::StaticValidation::FragmentsAreFinite do
  let(:query_string) {%|
    query getCheese {
      cheese(id: 1) {
        ... idField
        ... sourceField
        ... flavorField
      }
    }

    fragment sourceField on Cheese {
      source,
      ... flavorField
      ... idField
    }
    fragment flavorField on Cheese {
      flavor,
      ... sourceField
    }
    fragment idField on Cheese {
      id
    }
  |}

  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: DummySchema, rules: [GraphQL::StaticValidation::FragmentsAreFinite]) }
  let(:query) { GraphQL::Query.new(DummySchema, query_string) }
  let(:errors) { validator.validate(query) }

  it "doesnt allow infinite loops" do
    expected = [
      {
        "message"=>"Fragment sourceField contains an infinite loop",
        "locations"=>[{"line"=>10, "column"=>5}]
      },
      {
        "message"=>"Fragment flavorField contains an infinite loop",
        "locations"=>[{"line"=>15, "column"=>5}]
      }
    ]
    assert_equal(expected, errors)
  end
end
