# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::FieldsWillMerge do
  include StaticValidationHelpers

  let(:query_string) {"
    query getCheese($sourceVar: [DairyAnimal!] = [YAK]) {
      cheese(id: 1) {
        id,
        nickname: flavor,
        nickname: fatContent,
        fatContent
        differentLevel: fatContent
        similarCheese(source: $sourceVar) { __typename }

        similarCow: similarCheese(source: COW) {
          similarCowSource: source,
          differentLevel: fatContent
        }
        ...cheeseFields
        ... on Cheese {
          fatContent: flavor
          similarCheese(source: SHEEP) { __typename }
        }
      }
    }
    fragment cheeseFields on Cheese {
      fatContent,
      similarCow: similarCheese(source: COW) { similarCowSource: id, id }
      id @skip(if: true)
    }
  "}

  it "finds field naming conflicts" do
    expected_errors = [
      "Field 'nickname' has a field conflict: flavor or fatContent?",             # alias conflict in query
      "Field 'fatContent' has a field conflict: fatContent or flavor?",           # alias/name conflict in query and fragment
      "Field 'similarCheese' has an argument conflict: {\"source\":\"sourceVar\"} or {\"source\":\"SHEEP\"}?", # different arguments
      "Field 'similarCowSource' has a field conflict: source or id?",           # nested conflict
    ]
    assert_equal(expected_errors, error_messages)
  end
end
