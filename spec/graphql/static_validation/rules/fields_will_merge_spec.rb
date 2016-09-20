require "spec_helper"

describe GraphQL::StaticValidation::FieldsWillMerge do
  let(:query_string) {"
    query getCheese($sourceVar: DairyAnimal!) {
      cheese(id: 1) {
        id,
        nickname: name,
        nickname: fatContent,
        fatContent
        differentLevel: fatContent
        similarCheese(source: $sourceVar)

        similarCow: similarCheese(source: COW) {
          similarCowSource: source,
          differentLevel: fatContent
        }
        ...cheeseFields
        ... on Cheese {
          fatContent: name
          similarCheese(source: SHEEP)
        }
      }
    }
    fragment cheeseFields on Cheese {
      fatContent,
      similarCow: similarCheese(source: COW) { similarCowSource: id, id }
      id @someFlag
    }
  "}

  let(:validator) { GraphQL::StaticValidation::Validator.new(schema: DummySchema, rules: [GraphQL::StaticValidation::FieldsWillMerge]) }
  let(:query) { GraphQL::Query.new(DummySchema, query_string) }
  let(:errors) { validator.validate(query)[:errors] }
  let(:error_messages) { errors.map { |e| e["message" ] }}

  it "finds field naming conflicts" do
    expected_errors = [
      "Field 'nickname' has a field conflict: name or fatContent?",             # alias conflict in query
      "Field 'fatContent' has a field conflict: fatContent or name?",           # alias/name conflict in query and fragment
      "Field 'similarCheese' has an argument conflict: {\"source\":\"sourceVar\"} or {\"source\":\"SHEEP\"}?", # different arguments
      "Field 'similarCowSource' has a field conflict: source or id?",           # nested conflict
    ]
    assert_equal(expected_errors, error_messages)
  end
end
