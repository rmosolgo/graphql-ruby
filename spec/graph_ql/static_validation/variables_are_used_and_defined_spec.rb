require 'spec_helper'

describe GraphQL::StaticValidation::VariablesAreUsedAndDefined do
  let(:document) { GraphQL.parse('
    query getCheese($id: Int, $str: String, $notUsedVar: Float, $bool: Boolean) {
      cheese(id: $id) {
        source(str: $str)
        whatever(undefined: $undefinedVar)
        ... on Cheese {
          something(bool: $bool)
        }
      }
    }

    fragment outerCheeseFields on Cheese {
      ... innerCheeseFields
    }

    fragment innerCheeseFields on Cheese {
      source(notDefined: $notDefinedVar)
    }
  ')}

  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: DummySchema, validators: [GraphQL::StaticValidation::VariablesAreUsedAndDefined]) }
  let(:errors) { validator.validate(document) }

  it "finds variables which are used-but-not-defined or defined-but-not-used" do
    expected = [
      {
        "message"=>"Variable $undefinedVar is used but not declared",
        "locations"=>[{"line"=>5, "column"=>30}]
      },
      {
        "message"=>"Variable $notUsedVar is declared but not used",
        "locations"=>[{"line"=>2, "column"=>5}]
      },
      {
        "message"=>"Variable $notDefinedVar is used but not declared",
        "locations"=>[{"line"=>17, "column"=>27}]
      },
    ]
    assert_equal(expected, errors)
  end
end
