require 'spec_helper'

describe GraphQL::StaticValidation::FragmentsAreOnCompositeTypes do
  let(:document) { GraphQL.parse(%|
    query getCheese {
      cheese(id: 1) {
        ... on Cheese {
          source
          ... on Boolean {
            something
          }
        }
        ... intFields
        ... on DairyProduct {
          name
        }
        ... on DairyProductInput {
          something
        }
      }
    }

    fragment intFields on Int {
      something
    }
  |)}

  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: DummySchema, validators: [GraphQL::StaticValidation::FragmentsAreOnCompositeTypes]) }
  let(:errors) { validator.validate(document) }

  it 'requires Object/Union/Interface fragment types' do
    expected = [
      {
        "message"=>"Invalid fragment on type Boolean (must be Union, Interface or Object)",
        "locations"=>[{"line"=>6, "column"=>11}]
      },
      {
        "message"=>"Invalid fragment on type DairyProductInput (must be Union, Interface or Object)",
        "locations"=>[{"line"=>14, "column"=>9}],
      },
      {
        "message"=>"Invalid fragment on type Int (must be Union, Interface or Object)",
        "locations"=>[{"line"=>20, "column"=>5}]
      },
    ]
    assert_equal(expected, errors)
  end
end
