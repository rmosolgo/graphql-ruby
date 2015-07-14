require 'spec_helper'

class SchemaErrorValidator
  def validate(context)
    context.errors << "Something is wrong: #{context.schema}"
  end
end

class DocumentErrorValidator
  def validate(context)
    context.errors << "Something is wrong: #{context.document.name}"
  end
end

describe GraphQL::StaticValidation::Validator do
  let(:document)  { OpenStruct.new(name: "This is not a document", children: []) }
  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: "This is not a schema", validators: [SchemaErrorValidator, DocumentErrorValidator]) }

  it 'uses validators' do
    errors = validator.validate(document)
    expected_errors = ["Something is wrong: This is not a schema", "Something is wrong: This is not a document"]
    assert_equal(expected_errors, errors)
  end
end
