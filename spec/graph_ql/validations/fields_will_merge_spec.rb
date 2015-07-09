require 'spec_helper'

describe GraphQL::Validations::FieldsWillMerge do
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

  let(:validator) { GraphQL::Validator.new(schema: nil, validators: [GraphQL::Validations::FieldsWillMerge]) }
  let(:errors) { validator.validate(document) }
  it 'finds field naming conflicts' do
    expected_errors = [
      "Field 'nickname' has a conflict: name or fatContent?",             # alias conflict in query
      "Field 'originName' has a conflict: id or name?",                   # nested conflict
      "Field 'id' has a directive conflict: {} or {\"someFlag\":null}?",  # different directives
      "Field 'fatContent' has a conflict: fatContent or name?",           # alias/name conflict in query and fragment
      "Field 'similarCheeses' has an argument conflict: {\"source\":\"sourceVar\"} or {\"source\":\"SHEEP\"}?", # different arguments
    ]
    assert_equal(expected_errors, errors)
  end
end
