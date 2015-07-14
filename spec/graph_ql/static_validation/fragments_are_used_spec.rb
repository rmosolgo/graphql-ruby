require 'spec_helper'

describe GraphQL::StaticValidation::FragmentsAreUsed do
  let(:document) { GraphQL.parse("
    query getCheese {
      name,
      ...cheeseFields,
      origin {
        ...originFields
        ...undefinedFields
      }
    }
    fragment cheeseFields on Cheese { fatContent }
    fragment originFields on Country { name, continent { ...continentFields }}
    fragment continentFields on Continent { name }
    fragment unusedFields on Cheese { is, not, used }
  ")}

  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: nil, validators: [GraphQL::StaticValidation::FragmentsAreUsed]) }
  let(:errors) { validator.validate(document) }

  it 'adds errors for unused fragment definitions' do
    assert_includes(errors, 'Some fragments were defined but not used: unusedFields')
  end
  it 'adds errors for undefined fragment spreads' do
    assert_includes(errors, 'Some fragments were used but not defined: undefinedFields')
  end
end
