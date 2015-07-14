require 'spec_helper'

describe GraphQL::StaticValidation::FieldsAreDefinedOnType do
  let(:query_string) { "
    query getCheese($sourceVar: DairyAnimal!) {
      notDefinedField { name }
      cheese(id: 1) { nonsenseField, flavor }
      fromSource(source: COW) { bogusField }
    }

    fragment cheeseFields on Cheese { fatContent, hogwashField }
  "}

  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: DummySchema, validators: [GraphQL::StaticValidation::FieldsAreDefinedOnType]) }
  let(:errors) { validator.validate(GraphQL.parse(query_string)) }
  it "finds fields that are requested on types that don't have that field" do
    expected_errors = [
      "Field 'notDefinedField' doesn't exist on type 'Query'",  # from query root
      "Field 'nonsenseField' doesn't exist on type 'Cheese'",   # from another field
      "Field 'bogusField' doesn't exist on type 'Cheese'",      # from a list
      "Field 'hogwashField' doesn't exist on type 'Cheese'",    # from a fragment
    ]
    assert_equal(expected_errors, errors)
  end

  describe 'on interfaces' do
    let(:query_string) { "query getStuff { favoriteEdible { amountThatILikeIt } }"}
    it 'finds invalid fields' do
      expected_errors = [
        "Field 'amountThatILikeIt' doesn't exist on type 'Edible'"
      ]
      assert_equal(expected_errors, errors)
    end
  end

  describe 'on unions' do
    let(:query_string) { "
      query notOnUnion { favoriteEdible { ...dpFields } }
      fragment dbFields on DairyProduct { source }
      fragment dbIndirectFields on DairyProduct { ... on Cheese {source } }
    "}
    it 'doesnt allow selections on unions' do
      expected_errors = [
        "Selections can't be made directly on unions (see selections on DairyProduct)"
      ]
      assert_equal(expected_errors, errors)
    end
  end
end
