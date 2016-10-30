module GraphQL
  module Compatibility
    # This asserts that a given parse function turns a string into
    # the proper tree of {{GraphQL::Language::Nodes}}.
    module SchemaParserSpecification
      # @yieldparam query_string [String] A query string to parse
      # @yieldreturn [GraphQL::Language::Nodes::Document]
      # @return [Class<Minitest::Test>] A test suite for this parse function
      def self.build_suite(&block)
        Class.new(Minitest::Test) do
          @@parse_fn = block

          def parse(query_string)
            @@parse_fn.call(query_string)
          end

          def test_it_parses_object_types
            document = parse('
              type Comment implements Node @deprecated(reason: "No longer supported") {
                id: ID!
              }
            ')

            type = document.definitions.first
            assert_equal GraphQL::Language::Nodes::ObjectTypeDefinition, type.class
            assert_equal 'Comment', type.name
            assert_equal ['Node'], type.interfaces.map(&:name)
            assert_equal ['id'], type.fields.map(&:name)
            assert_equal [], type.fields[0].arguments
            assert_equal 'ID', type.fields[0].type.of_type.name
            assert_equal 1, type.directives.length

            deprecated_directive = type.directives[0]
            assert_equal 'deprecated', deprecated_directive.name
            assert_equal 'reason', deprecated_directive.arguments[0].name
            assert_equal 'No longer supported', deprecated_directive.arguments[0].value
          end

          def test_it_parses_schema_definition
            document = parse('
              schema {
                query: QueryRoot
                mutation: MutationRoot
                subscription: SubscriptionRoot
              }
            ')

            schema = document.definitions.first
            assert_equal 'QueryRoot', schema.query
            assert_equal 'MutationRoot', schema.mutation
            assert_equal 'SubscriptionRoot', schema.subscription
          end

          def test_it_parses_whole_definition_with_descriptions
            document = parse(SCHEMA_DEFINITION_STRING)

            assert_equal 6, document.definitions.size

            schema_definition = document.definitions.shift
            assert_equal GraphQL::Language::Nodes::SchemaDefinition, schema_definition.class

            directive_definition = document.definitions.shift
            assert_equal GraphQL::Language::Nodes::DirectiveDefinition, directive_definition.class
            assert_equal 'This is a directive', directive_definition.description

            enum_type_definition = document.definitions.shift
            assert_equal GraphQL::Language::Nodes::EnumTypeDefinition, enum_type_definition.class
            assert_equal "Multiline comment\n\nWith an enum", enum_type_definition.description

            assert_nil enum_type_definition.values[0].description
            assert_equal 'Not a creative color', enum_type_definition.values[1].description

            object_type_definition = document.definitions.shift
            assert_equal GraphQL::Language::Nodes::ObjectTypeDefinition, object_type_definition.class
            assert_equal 'Comment without preceding space', object_type_definition.description
            assert_equal 'And a field to boot', object_type_definition.fields[0].description

            input_object_type_definition = document.definitions.shift
            assert_equal GraphQL::Language::Nodes::InputObjectTypeDefinition, input_object_type_definition.class
            assert_equal 'Comment for input object types', input_object_type_definition.description
            assert_equal 'Color of the car', input_object_type_definition.fields[0].description

            interface_type_definition = document.definitions.shift
            assert_equal GraphQL::Language::Nodes::InterfaceTypeDefinition, interface_type_definition.class
            assert_equal 'Comment for interface definitions', interface_type_definition.description
            assert_equal 'Amount of wheels', interface_type_definition.fields[0].description
          end
        end
      end

      SCHEMA_DEFINITION_STRING = %|
        # Schema at beginning of file

        schema {
          query: Hello
        }

        # Comment between two definitions are omitted

        # This is a directive
        directive @foo(
          # It has an argument
          arg: Int
        ) on FIELD

        # Multiline comment
        #
        # With an enum
        enum Color {
          RED

          # Not a creative color
          GREEN
          BLUE
        }

        #Comment without preceding space
        type Hello {
          # And a field to boot
          str: String
        }

        # Comment for input object types
        input Car {
          # Color of the car
          color: String!
        }

        # Comment for interface definitions
        interface Vehicle {
          # Amount of wheels
          wheels: Int!
        }

        # Comment at the end of schema
      |
    end
  end
end
