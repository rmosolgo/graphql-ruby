# frozen_string_literal: true
module GraphQL
  module Compatibility
    module QueryParserSpecification
      module ParseErrorSpecification
        def assert_raises_parse_error(query_string)
          assert_raises(GraphQL::ParseError) {
            parse(query_string)
          }
        end

        def test_it_includes_line_and_column
          err = assert_raises_parse_error("
            query getCoupons {
              allCoupons: {data{id}}
            }
          ")

          assert_includes(err.message, '{')
          assert_equal(3, err.line)
          assert_equal(27, err.col)
        end

        def test_it_rejects_unterminated_strings
          assert_raises_parse_error('{ " }')
          assert_raises_parse_error(%|{ "\n" }|)
        end

        def test_it_rejects_unexpected_ends
          assert_raises_parse_error("query { stuff { thing }")
        end

        def assert_rejects_character(char)
          err = assert_raises_parse_error("{ field#{char} }")
          expected_char = char.inspect.gsub('"', '').downcase
          msg_downcase = err.message.downcase
          # Case-insensitive for UTF-8 printing
          assert_includes(msg_downcase, expected_char, "The message includes the invalid character")
        end

        def test_it_rejects_invalid_characters
          assert_rejects_character(";")
          assert_rejects_character("\a")
          assert_rejects_character("\xef")
          assert_rejects_character("\v")
          assert_rejects_character("\f")
          assert_rejects_character("\xa0")
        end

        def test_it_rejects_bad_unicode
          assert_raises_parse_error(%|{ field(arg:"\\x") }|)
          assert_raises_parse_error(%|{ field(arg:"\\u1") }|)
          assert_raises_parse_error(%|{ field(arg:"\\u0XX1") }|)
          assert_raises_parse_error(%|{ field(arg:"\\uXXXX") }|)
          assert_raises_parse_error(%|{ field(arg:"\\uFXXX") }|)
          assert_raises_parse_error(%|{ field(arg:"\\uXXXF") }|)
        end

        def test_it_rejects_empty_inline_fragments
          assert_raises_parse_error("
            query {
              viewer {
                login {
                  ... on String {

                  }
                }
              }
            }
          ")
        end

        def test_it_rejects_blank_queries
          assert_raises_parse_error("")
          assert_raises_parse_error(" ")
          assert_raises_parse_error("\t \t")
          assert_raises_parse_error(" # comment ")
        end

        def test_it_restricts_on
          assert_raises_parse_error("{ ...on }")
          assert_raises_parse_error("fragment on on Type { field }")
        end
      end
    end
  end
end
