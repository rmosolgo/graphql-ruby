# frozen_string_literal: true
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

    it "makes utf-8 comments" do
      tokens = subject.tokenize("# 不要!\n{")
      comment_token = tokens.first.prev_token
      assert_equal "# 不要!", comment_token.to_s
    end

    it "keeps track of previous_token" do
      assert_equal tokens[0], tokens[1].prev_token
    end

    describe "block strings" do
      let(:query_string) { %|{ a(b: """\nc\n  d\n""")}|}

      it "tokenizes them" do
        str_token = tokens[5]
        assert_equal "c\n  d", str_token.value
      end
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

    it "clears the previous_token between runs" do
      tok_2 = subject.tokenize(query_string)
      assert_nil tok_2[0].prev_token
    end

    it "counts string position properly" do
      tokens = subject.tokenize('{ a(b: "c")}')
      str_token = tokens[5]
      assert_equal :STRING, str_token.name
      assert_equal "c", str_token.value
      assert_equal 8, str_token.col
      assert_equal '(STRING "c" [1:8])', str_token.inspect
      rparen_token = tokens[6]
      assert_equal '(RPAREN ")" [1:10])', rparen_token.inspect
    end
  end
end
