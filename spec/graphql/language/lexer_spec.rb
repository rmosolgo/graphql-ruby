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

    it "allows escaped quotes in strings" do
      tokens = subject.tokenize('"a\\"b""c"')
      assert_equal 'a"b', tokens[0].value
      assert_equal 'c', tokens[1].value
    end

    describe "block strings" do
      let(:query_string) { %|{ a(b: """\nc\n \\""" d\n""" """""e""""")}|}

      it "tokenizes them" do
        assert_equal "c\n \"\"\" d", tokens[5].value
        assert_equal "\"\"e\"\"", tokens[6].value
      end

      it "tokenizes 10 quote edge case correctly" do
        tokens = subject.tokenize('""""""""""')
        assert_equal '""', tokens[0].value # first 8 quotes are a valid block string """"""""
        assert_equal '', tokens[1].value # last 2 quotes are a valid string ""
      end

      it "tokenizes with nested single quote strings correctly" do
        tokens = subject.tokenize('"""{"x"}"""')
        assert_equal '{"x"}', tokens[0].value

        tokens = subject.tokenize('"""{"foo":"bar"}"""')
        assert_equal '{"foo":"bar"}', tokens[0].value
      end

      it "tokenizes empty block strings correctly" do
        empty_block_string = '""""""'
        tokens = subject.tokenize(empty_block_string)

        assert_equal '', tokens[0].value
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

    it "rejects truly invalid UTF-8 bytes" do
      error_filename = "spec/support/parser/filename_example_invalid_utf8.graphql"
      assert_equal :BAD_UNICODE_ESCAPE, subject.tokenize(File.read(error_filename)).first.name
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
      assert_equal '(RPAREN ")" [1:11])', rparen_token.inspect
    end

    it "counts block string line properly" do
      str = <<-GRAPHQL
      """
      Here is a
      multiline description
      """
      type Query {
        a: B
      }

      "Here's another description"

      type B {
        a: B
      }

      """
      And another
      multiline description
      """


      type C {
        a: B
      }
      GRAPHQL

      tokens = subject.tokenize(str)

      string_tok, type_keyword_tok, query_name_tok,
        _curly, _ident, _colon, _ident, _curly,
        string_tok_2, type_keyword_tok_2, b_name_tok,
        _curly, _ident, _colon, _ident, _curly,
        string_tok_3, type_keyword_tok_3, c_name_tok = tokens

      assert_equal 1, string_tok.line
      assert_equal 5, type_keyword_tok.line
      assert_equal 5, query_name_tok.line

      # Make sure it handles the empty spaces, too
      assert_equal 9, string_tok_2.line
      assert_equal 11, type_keyword_tok_2.line
      assert_equal 11, b_name_tok.line

      assert_equal 15, string_tok_3.line
      assert_equal 21, type_keyword_tok_3.line
      assert_equal 21, c_name_tok.line
    end
  end
end
