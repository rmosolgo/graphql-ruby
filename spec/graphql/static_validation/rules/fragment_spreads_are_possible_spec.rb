require "spec_helper"

describe GraphQL::StaticValidation::FragmentSpreadsArePossible do
  let(:query_string) {%|
    query getCheese {
      cheese(id: 1) {
        ... milkFields
        ... cheeseFields
        ... on Milk { fatContent }
        ... on AnimalProduct { source }
        ... on DairyProduct {
          fatContent
          ... on Edible { fatContent }
        }
      }
    }

    fragment milkFields on Milk { fatContent }
    fragment cheeseFields on Cheese {
      fatContent
      ... milkFields
    }
  |}

  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: DummySchema, rules: [GraphQL::StaticValidation::FragmentSpreadsArePossible]) }
  let(:query) { GraphQL::Query.new(DummySchema, query_string) }
  let(:errors) { validator.validate(query) }

  it "doesnt allow spreads where they'll never apply" do
    # TODO: more negative, abstract examples here, add stuff to the schema
    expected = [
      {
        "message"=>"Fragment on Milk can't be spread inside Cheese",
        "locations"=>[{"line"=>6, "column"=>9}]
      },
      {
        "message"=>"Fragment milkFields on Milk can't be spread inside Cheese",
        "locations"=>[{"line"=>4, "column"=>9}]
      },
      {
        "message"=>"Fragment milkFields on Milk can't be spread inside Cheese",
        "locations"=>[{"line"=>18, "column"=>7}]
      }
    ]
    assert_equal(expected, errors)
  end
end
