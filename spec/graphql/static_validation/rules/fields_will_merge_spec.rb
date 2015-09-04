require 'spec_helper'

describe GraphQL::StaticValidation::FieldsWillMerge do
  let(:document) { GraphQL.parse("
    query getCheese($sourceVar: DairyAnimal!) {
      cheese(id: 1) {
        id,
        nickname: name,
        nickname: fatContent,
        fatContent
        differentLevel: fatContent
        similarCheeses(source: $sourceVar)

        similarCow: similarCheeses(source: COW) {
          similarCowSource: source,
          differentLevel: fatContent
        }
        ...cheeseFields
        ... on Cheese {
          fatContent: name
          similarCheeses(source: SHEEP)
        }
      }
    }
    fragment cheeseFields on Cheese {
      fatContent,
      similarCow: similarCheeses(source: COW) { similarCowSource: id, id }
      id @someFlag
    }
  ")}

  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: DummySchema, rules: [GraphQL::StaticValidation::FieldsWillMerge]) }
  let(:errors) { validator.validate(document) }
  let(:error_messages) { errors.map { |e| e["message" ] }}

  it 'finds field naming conflicts' do
    expected_errors = [
      "Field 'id' has a directive conflict: [] or [someFlag]?",                 # different directives
      "Field 'id' has a directive argument conflict: [] or [{}]?",              # not sure this is a great way to handle it but here we are!
      "Field 'nickname' has a field conflict: name or fatContent?",             # alias conflict in query
      "Field 'fatContent' has a field conflict: fatContent or name?",           # alias/name conflict in query and fragment
      "Field 'similarCheeses' has an argument conflict: {\"source\":\"sourceVar\"} or {\"source\":\"SHEEP\"}?", # different arguments
      "Field 'similarCowSource' has a field conflict: source or id?",           # nested conflict
    ]
    assert_equal(expected_errors, error_messages)
  end
end
