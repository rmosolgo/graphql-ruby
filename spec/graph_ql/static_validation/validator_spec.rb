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
  let(:document)  { OpenStruct.new(name: "This is not a document", children: []) }
  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: "This is not a schema", rules: [SchemaErrorValidator, DocumentErrorValidator]) }

  it 'uses rules' do
    errors = validator.validate(document)
    expected_errors = [
      {"message" => "Something is wrong: This is not a schema", "locations" => [{"line" => 100, "column" => 4}]},
      {"message" => "Something is wrong: This is not a document", "locations" => [{"line" => 1, "column" => 1}]}
    ]
    assert_equal(expected_errors, errors)
  end
end
