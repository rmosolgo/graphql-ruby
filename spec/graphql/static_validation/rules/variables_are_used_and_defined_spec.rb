require "spec_helper"

describe GraphQL::StaticValidation::VariablesAreUsedAndDefined do
  let(:query_string) {'
    query getCheese(
      $usedVar: Int,
      $usedInnerVar: String,
      $usedInlineFragmentVar: Boolean,
      $usedFragmentVar: Int,
      $notUsedVar: Float,
    ) {
      cheese(id: $usedVar) {
        source(str: $usedInnerVar)
        whatever(undefined: $undefinedVar)
        ... on Cheese {
          something(bool: $usedInlineFragmentVar)
        }
        ... outerCheeseFields
      }
    }

    fragment outerCheeseFields on Cheese {
      ... innerCheeseFields
    }

    fragment innerCheeseFields on Cheese {
      source(notDefined: $undefinedFragmentVar)
      someField(someArg: $usedFragmentVar)
    }
  '}

  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: DummySchema, rules: [GraphQL::StaticValidation::VariablesAreUsedAndDefined]) }
  let(:query) { GraphQL::Query.new(DummySchema, query_string) }
  let(:errors) { validator.validate(query)[:errors] }

  it "finds variables which are used-but-not-defined or defined-but-not-used" do
    expected = [
      {
        "message"=>"Variable $notUsedVar is declared by getCheese but not used",
        "locations"=>[{"line"=>2, "column"=>5}],
        "path"=>["query getCheese"],
      },
      {
        "message"=>"Variable $undefinedVar is used by getCheese but not declared",
        "locations"=>[{"line"=>11, "column"=>29}],
        "path"=>["query getCheese", "cheese", "whatever", "undefined"],
      },
      {
        "message"=>"Variable $undefinedFragmentVar is used by innerCheeseFields but not declared",
        "locations"=>[{"line"=>24, "column"=>26}],
        "path"=>["fragment innerCheeseFields", "source", "notDefined"],
      },
    ]
    assert_equal(expected, errors)
  end
end
