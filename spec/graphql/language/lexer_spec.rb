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

    it "unescapes escaped characters" do
      assert_equal "\" \\ / \b \f \n \r \t", subject.tokenize('"\\" \\\\ \\/ \\b \\f \\n \\r \\t"').first.to_s
    end

    it "unescapes escaped unicode characters" do
      assert_equal "\t", subject.tokenize('"\\u0009"').first.to_s
    end

    it "rejects bad unicode, even when there's good unicode in the string" do
      assert_equal :BAD_UNICODE_ESCAPE, subject.tokenize('"\\u0XXF \\u0009"').first.name
    end
  end
end
