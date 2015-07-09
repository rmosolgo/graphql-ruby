require 'spec_helper'

describe GraphQL::Validations::FieldsAreDefinedOnType do
  let(:document) { GraphQL.parse("
    query getCheese($sourceVar: DairyAnimal!) {
      notDefinedField { name }
      cheese(id: 1) { nonsenseField, flavor }
      fromSource(source: COW) { bogusField }
    }

    fragment cheeseFields on Cheese { fatContent, hogwashField }
  ")}

  let(:validator) { GraphQL::Validator.new(schema: DummySchema, validators: [GraphQL::Validations::FieldsAreDefinedOnType]) }
  let(:errors) { validator.validate(document) }
  it "finds fields that are requested on types that don't have that field" do
    expected_errors = [
      "Field 'notDefinedField' doesn't exist on type 'Query'",  # from query root
      "Field 'nonsenseField' doesn't exist on type 'Cheese'",   # from another field
      "Field 'bogusField' doesn't exist on type 'Cheese'",      # from a list
      "Field 'hogwashField' doesn't exist on type 'Cheese'",    # from a fragment
    ]
    assert_equal(expected_errors, errors)
  end

  it 'finds invalid fields on interfaces'
  it 'finds invalid fields on unions'
end
