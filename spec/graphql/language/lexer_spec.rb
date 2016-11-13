require "spec_helper"

describe GraphQL::Language::Lexer do
  subject { GraphQL::Language::Lexer }

  describe ".tokenize" do
    let(:query_string) {%|
      {
        query getCheese {
          cheese(id: 1) {
            ... cheeseFields
          }
        }
      }
    |}
    let(:tokens) { subject.tokenize(query_string) }

    it "keeps track of previous_token" do
      assert_equal tokens[0], tokens[1].prev_token
    end

    it "clears the previous_token between runs" do
      tok_1 = subject.tokenize(query_string)
      tok_2 = subject.tokenize(query_string)
      assert_equal nil, tok_2[0].prev_token
    end
  end
end
