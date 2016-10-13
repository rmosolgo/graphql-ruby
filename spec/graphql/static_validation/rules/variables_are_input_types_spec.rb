require "spec_helper"

describe GraphQL::StaticValidation::VariablesAreInputTypes do
  include StaticValidationHelpers

  let(:query_string) {'
    query getCheese(
      $id:        Int = 1,
      $str:       [String!],
      $interface: AnimalProduct!,
      $object:    Milk = 1,
      $objects:   [Cheese]!,
      $unknownType: Nonsense,
    ) {
      cheese(id: $id) { source }
      __type(name: $str) { name }
    }
  '}

  it "finds variables whose types are invalid" do
    assert_includes(errors, {
      "message"=>"AnimalProduct isn't a valid input type (on $interface)",
      "locations"=>[{"line"=>5, "column"=>7}],
      "fields"=>["query getCheese"],
    })

    assert_includes(errors, {
      "message"=>"Milk isn't a valid input type (on $object)",
      "locations"=>[{"line"=>6, "column"=>7}],
      "fields"=>["query getCheese"],
    })

    assert_includes(errors, {
      "message"=>"Cheese isn't a valid input type (on $objects)",
      "locations"=>[{"line"=>7, "column"=>7}],
      "fields"=>["query getCheese"],
    })

    assert_includes(errors, {
      "message"=>"Nonsense isn't a defined input type (on $unknownType)",
      "locations"=>[{"line"=>8, "column"=>7}],
      "fields"=>["query getCheese"],
    })
  end
end
