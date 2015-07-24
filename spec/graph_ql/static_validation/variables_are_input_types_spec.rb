require 'spec_helper'

describe GraphQL::StaticValidation::VariablesAreInputTypes do
  let(:document) { GraphQL.parse('
    query getCheese(
      $id:        Int = 1,
      $str:       [String!],
      $interface: AnimalProduct!,
      $object:    Milk = 1,
      $objects:   [Cheese]!,
    ) {
      cheese(id: $id) { source }
    }
  ')}

  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: DummySchema, validators: [GraphQL::StaticValidation::VariablesAreInputTypes]) }
  let(:errors) { validator.validate(document) }

  it "finds variables whose types are invalid" do
    expected = [
      {
        "message"=>"AnimalProduct isn't a valid input type (on $interface)",
        "locations"=>[{"line"=>5, "column"=>8}]
      },
      {
        "message"=>"Milk isn't a valid input type (on $object)",
        "locations"=>[{"line"=>6, "column"=>8}]
      },
      {
        "message"=>"Cheese isn't a valid input type (on $objects)",
        "locations"=>[{"line"=>7, "column"=>8}]
      }
    ]
    assert_equal(expected, errors)
  end
end
