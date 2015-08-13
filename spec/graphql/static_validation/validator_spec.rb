require 'spec_helper'

class SchemaErrorValidator
  def validate(context)
    context.errors << GraphQL::StaticValidation::Message.new("Something is wrong: #{context.schema}", line: 100, col: 4)
  end
end

class DocumentErrorValidator
  include
  def validate(context)
    context.errors << GraphQL::StaticValidation::Message.new("Something is wrong: #{context.document.name}", line: 1, col: 1)
  end
end

describe GraphQL::StaticValidation::Validator do
  let(:document)  { OpenStruct.new(name: "This is not a document", children: [], parts: []) }
  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: "This is not a schema", rules: [SchemaErrorValidator, DocumentErrorValidator]) }
  let(:errors) { validator.validate(document) }
  it 'uses rules' do
    expected_errors = [
      {"message" => "Something is wrong: This is not a schema", "locations" => [{"line" => 100, "column" => 4}]},
      {"message" => "Something is wrong: This is not a document", "locations" => [{"line" => 1, "column" => 1}]}
    ]
    assert_equal(expected_errors, errors)
  end

  describe 'validation order' do
    let(:validator) { GraphQL::StaticValidation::Validator.new(schema: DummySchema) }
    let(:document) { GraphQL.parse(query_string)}

    describe 'fields & arguments' do
      let(:query_string) { %|
        query getCheese {
          cheese(id: 1) {
            source,
            nonsenseField,
            id(nonsenseArg: 1)
            bogusField(bogusArg: true)
          }
        }
      |}

      it 'handles args on invalid fields' do
        assert_equal(3, errors.length)
      end
    end

    describe 'infinite fragments' do
      let(:query_string) { %|
        query getCheese {
          cheese(id: 1) {
            ... cheeseFields
          }
        }
        fragment cheeseFields on Cheese {
          id, ... cheeseFields
        }
      |}

      it 'handles infinite fragment spreads' do
        assert_equal(1, errors.length)
      end
    end
  end
end
