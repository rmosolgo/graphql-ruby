require "spec_helper"

describe GraphQL::StaticValidation::VariablesAreInputTypes do
  let(:query_string) {'
    query getCheese(
      $id:        Int = 1,
      $str:       [String!],
      $interface: AnimalProduct!,
      $object:    Milk = 1,
      $objects:   [Cheese]!,
    ) {
      cheese(id: $id) { source }
    }
  '}

  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: DairySchema, rules: [GraphQL::StaticValidation::VariablesAreInputTypes]) }
  let(:query) { GraphQL::Query.new(DairySchema, query_string) }
  let(:errors) { validator.validate(query)[:errors] }

  it "finds variables whose types are invalid" do
    expected = [
      {
        "message"=>"AnimalProduct isn't a valid input type (on $interface)",
        "locations"=>[{"line"=>5, "column"=>7}],
        "path"=>["query getCheese"],
      },
      {
        "message"=>"Milk isn't a valid input type (on $object)",
        "locations"=>[{"line"=>6, "column"=>7}],
        "path"=>["query getCheese"],
      },
      {
        "message"=>"Cheese isn't a valid input type (on $objects)",
        "locations"=>[{"line"=>7, "column"=>7}],
        "path"=>["query getCheese"],
      }
    ]
    assert_equal(expected, errors)
  end
end
