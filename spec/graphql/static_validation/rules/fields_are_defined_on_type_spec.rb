require "spec_helper"

describe GraphQL::StaticValidation::FieldsAreDefinedOnType do
  let(:query_string) { "
    query getCheese($sourceVar: DairyAnimal!) {
      notDefinedField { name }
      cheese(id: 1) { nonsenseField, flavor }
      fromSource(source: COW) { bogusField }
    }

    fragment cheeseFields on Cheese { fatContent, hogwashField }
  "}

  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: DummySchema, rules: [GraphQL::StaticValidation::FieldsAreDefinedOnType]) }
  let(:query) { GraphQL::Query.new(DummySchema, query_string) }
  let(:errors) { validator.validate(query) }
  let(:error_messages) { errors.map { |e| e["message"] } }

  it "finds fields that are requested on types that don't have that field" do
    expected_errors = [
      "Field 'notDefinedField' doesn't exist on type 'Query'",  # from query root
      "Field 'nonsenseField' doesn't exist on type 'Cheese'",   # from another field
      "Field 'bogusField' doesn't exist on type 'Cheese'",      # from a list
      "Field 'hogwashField' doesn't exist on type 'Cheese'",    # from a fragment
    ]
    assert_equal(expected_errors, error_messages)
  end

  describe "on interfaces" do
    let(:query_string) { "query getStuff { favoriteEdible { amountThatILikeIt } }"}

    it "finds invalid fields" do
      expected_errors = [
        {"message"=>"Field 'amountThatILikeIt' doesn't exist on type 'Edible'", "locations"=>[{"line"=>1, "column"=>18}]}
      ]
      assert_equal(expected_errors, errors)
    end
  end

  describe "on unions" do
    let(:query_string) { "
      query notOnUnion { favoriteEdible { ...dpFields } }
      fragment dbFields on DairyProduct { source }
      fragment dbIndirectFields on DairyProduct { ... on Cheese { source } }
    "}


    it "doesnt allow selections on unions" do
      expected_errors = [
        {
          "message"=>"Selections can't be made directly on unions (see selections on DairyProduct)",
          "locations"=>[
            {"line"=>3, "column"=>7}
          ]
        }
      ]
      assert_equal(expected_errors, errors)
    end
  end
end
