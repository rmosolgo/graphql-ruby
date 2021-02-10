# frozen_string_literal: true
require "graphql/compatibility/query_parser_specification/query_assertions"
require "graphql/compatibility/query_parser_specification/parse_error_specification"

module GraphQL
  module Compatibility
    # This asserts that a given parse function turns a string into
    # the proper tree of {{GraphQL::Language::Nodes}}.
    module QueryParserSpecification
      # @yieldparam query_string [String] A query string to parse
      # @yieldreturn [GraphQL::Language::Nodes::Document]
      # @return [Class<Minitest::Test>] A test suite for this parse function
      def self.build_suite(&block)
        GraphQL::Deprecation.warn "#{self} will be removed from GraphQL-Ruby 2.0. There is no replacement, please open an issue on GitHub if you need support."

        Class.new(Minitest::Test) do
          include QueryAssertions
          include ParseErrorSpecification

          @@parse_fn = block

          def parse(query_string)
            @@parse_fn.call(query_string)
          end

          def test_it_parses_queries
            document = parse(QUERY_STRING)
            query = document.definitions.first
            assert_valid_query(query)
            assert_valid_fragment(document.definitions.last)
            assert_valid_variable(query.variables.first)
            field = query.selections.first
            assert_valid_field(field)
            assert_valid_variable_argument(field.arguments.first)
            assert_valid_literal_argument(field.arguments.last)
            assert_valid_directive(field.directives.first)
            fragment_spread = query.selections[1].selections.last
            assert_valid_fragment_spread(fragment_spread)
            assert_valid_typed_inline_fragment(query.selections[2])
            assert_valid_typeless_inline_fragment(query.selections[3])
          end

          def test_it_parses_unnamed_queries
            document = parse("{ name, age, height }")
            operation =  document.definitions.first
            assert_equal 1, document.definitions.length
            assert_equal "query", operation.operation_type
            assert_equal nil, operation.name
            assert_equal 3, operation.selections.length
          end

          def test_it_parses_the_introspection_query
            parse(GraphQL::Introspection::INTROSPECTION_QUERY)
          end

          def test_it_parses_inputs
            query_string = %|
              {
                field(
                  int: 3,
                  float: 4.7e-24,
                  bool: false,
                  string: "☀︎🏆 \\b \\f \\n \\r \\t \\" \u00b6 \\u00b6 / \\/",
                  enum: ENUM_NAME,
                  array: [7, 8, 9]
                  object: {a: [1,2,3], b: {c: "4"}}
                  unicode_bom: "\xef\xbb\xbfquery"
                  keywordEnum: on
                  nullValue: null
                  nullValueInObject: {a: null, b: "b"}
                  nullValueInArray: ["a", null, "b"]
                  blockString: """
                  Hello,
                    World
                  """
                )
              }
            |
            document = parse(query_string)
            inputs = document.definitions.first.selections.first.arguments
            assert_equal 3, inputs[0].value, "Integers"
            assert_equal 0.47e-23, inputs[1].value, "Floats"
            assert_equal false, inputs[2].value, "Booleans"
            assert_equal %|☀︎🏆 \b \f \n \r \t " ¶ ¶ / /|, inputs[3].value, "Strings"
            assert_instance_of GraphQL::Language::Nodes::Enum, inputs[4].value
            assert_equal "ENUM_NAME", inputs[4].value.name, "Enums"
            assert_equal [7,8,9], inputs[5].value, "Lists"

            obj = inputs[6].value
            assert_equal "a", obj.arguments[0].name
            assert_equal [1,2,3], obj.arguments[0].value
            assert_equal "b", obj.arguments[1].name
            assert_equal "c", obj.arguments[1].value.arguments[0].name
            assert_equal "4", obj.arguments[1].value.arguments[0].value

            assert_equal %|\xef\xbb\xbfquery|, inputs[7].value, "Unicode BOM"
            assert_equal "on", inputs[8].value.name, "Enum value 'on'"

            assert_instance_of GraphQL::Language::Nodes::NullValue, inputs[9].value

            args = inputs[10].value.arguments
            assert_instance_of GraphQL::Language::Nodes::NullValue, args.find{ |arg| arg.name == 'a' }.value
            assert_equal 'b', args.find{ |arg| arg.name == 'b' }.value

            values = inputs[11].value
            assert_equal 'a', values[0]
            assert_instance_of GraphQL::Language::Nodes::NullValue, values[1]
            assert_equal 'b', values[2]

            block_str_value = inputs[12].value
            assert_equal "Hello,\n  World", block_str_value
          end

          def test_it_doesnt_parse_nonsense_variables
            query_string_1 = "query Vars($var1) { cheese(id: $var1) { flavor } }"
            query_string_2 = "query Vars2($var1: Int = $var1) { cheese(id: $var1) { flavor } }"

            err_1 = assert_raises(GraphQL::ParseError) do
              parse(query_string_1)
            end
            assert_equal [1,17], [err_1.line, err_1.col]

            err_2 = assert_raises(GraphQL::ParseError) do
              parse(query_string_2)
            end
            assert_equal [1,26], [err_2.line, err_2.col]
          end

          def test_enum_value_definitions_have_a_position
            document = parse("""
              enum Enum {
                VALUE
              }
            """)

            assert_equal [3, 17], document.definitions[0].values[0].position
          end

          def test_field_definitions_have_a_position
            document = parse("""
              type A {
                field: String
              }
            """)

            assert_equal [3, 17], document.definitions[0].fields[0].position
          end

          def test_input_value_definitions_have_a_position
            document = parse("""
              input A {
                field: String
              }
            """)

            assert_equal [3, 17], document.definitions[0].fields[0].position
          end

          def test_parses_when_there_are_no_interfaces
            schema = "
              type A {
                a: String
              }
            "

            document = parse(schema)

            assert_equal [], document.definitions[0].interfaces.map(&:name)
          end

          def test_parses_implements_with_leading_ampersand
            schema = "
              type A implements & B {
                a: String
              }
            "

            document = parse(schema)

            assert_equal ["B"], document.definitions[0].interfaces.map(&:name)
            assert_equal [2, 35], document.definitions[0].interfaces[0].position
          end

          def test_parses_implements_with_leading_ampersand_and_multiple_interfaces
            schema = "
              type A implements & B & C {
                a: String
              }
            "

            document = parse(schema)

            assert_equal ["B", "C"], document.definitions[0].interfaces.map(&:name)
            assert_equal [2, 35], document.definitions[0].interfaces[0].position
            assert_equal [2, 39], document.definitions[0].interfaces[1].position
          end

          def test_parses_implements_without_leading_ampersand
            schema = "
              type A implements B {
                a: String
              }
            "

            document = parse(schema)

            assert_equal ["B"], document.definitions[0].interfaces.map(&:name)
            assert_equal [2, 33], document.definitions[0].interfaces[0].position
          end

          def test_parses_implements_without_leading_ampersand_and_multiple_interfaces
            schema = "
              type A implements B & C {
                a: String
              }
            "

            document = parse(schema)

            assert_equal ["B", "C"], document.definitions[0].interfaces.map(&:name)
            assert_equal [2, 33], document.definitions[0].interfaces[0].position
            assert_equal [2, 37], document.definitions[0].interfaces[1].position
          end

          def test_supports_old_syntax_for_parsing_multiple_interfaces
            schema = "
              type A implements B, C {
                a: String
              }
            "

            document = parse(schema)

            assert_equal ["B", "C"], document.definitions[0].interfaces.map(&:name)
            assert_equal [2, 33], document.definitions[0].interfaces[0].position
            assert_equal [2, 36], document.definitions[0].interfaces[1].position
          end
        end
      end

      QUERY_STRING = %|
            query getStuff($someVar: Int = 1, $anotherVar: [String!] ) @skip(if: false) {
              myField: someField(someArg: $someVar, ok: 1.4) @skip(if: $anotherVar) @thing(or: "Whatever")

              anotherField(someArg: [1,2,3]) {
                nestedField
                ... moreNestedFields @skip(if: true)
              }

              ... on OtherType @include(unless: false){
                field(arg: [{key: "value", anotherKey: 0.9, anotherAnotherKey: WHATEVER}])
                anotherField
              }

              ... {
                id
              }
            }

            fragment moreNestedFields on NestedType @or(something: "ok") {
              anotherNestedField @enum(directive: true)
            }
      |
    end
  end
end
