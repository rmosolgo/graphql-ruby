require 'spec_helper'

describe GraphQL::StaticValidation::FieldsWillMerge do
  let(:document) { GraphQL.parse("
    query getCheese($sourceVar: DairyAnimal!) {
      id
      nickname: name,
      nickname: fatContent,
      fatContent

      similarCheeses(source: $sourceVar)

      origin { originName: id },
      ...cheeseFields
      ... on Cheese {
        fatContent: name
        similarCheeses(source: SHEEP)
      }
    }
    fragment cheeseFields on Cheese {
      fatContent,
      origin { originName: name }
      id @someFlag
    }
  ")}

  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: nil, validators: [GraphQL::StaticValidation::FieldsWillMerge]) }
  let(:errors) { validator.validate(document) }
  let(:error_messages) { errors.map { |e| e["message" ] }}

  it 'finds field naming conflicts' do
    expected_errors = [
      "Field 'nickname' has a field conflict: name or fatContent?",             # alias conflict in query
      "Field 'originName' has a field conflict: id or name?",                   # nested conflict
      "Field 'id' has a directive conflict: [] or [someFlag]?",                 # different directives
      "Field 'id' has a directive argument conflict: [] or [{}]?",              # not sure this is a great way to handle it but here we are!
      "Field 'fatContent' has a field conflict: fatContent or name?",           # alias/name conflict in query and fragment
      "Field 'similarCheeses' has an argument conflict: {\"source\":\"sourceVar\"} or {\"source\":\"SHEEP\"}?", # different arguments
    ]
    assert_equal(expected_errors, error_messages)
  end
end
