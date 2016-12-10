# frozen_string_literal: true
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
              # This is what
              # somebody said about something
              type Comment implements Node @deprecated(reason: "No longer supported") {
                id: ID!
              }
            ')

            type = document.definitions.first
            assert_equal GraphQL::Language::Nodes::ObjectTypeDefinition, type.class
            assert_equal 'Comment', type.name
            assert_equal "This is what\nsomebody said about something", type.description
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

          def test_it_parses_scalars
            document = parse('scalar DateTime')

            type = document.definitions.first
            assert_equal GraphQL::Language::Nodes::ScalarTypeDefinition, type.class
            assert_equal 'DateTime', type.name
          end

          def test_it_parses_enum_types
            document = parse('
              enum DogCommand {
                # Good dog
                SIT
                DOWN @deprecated(reason: "No longer supported")
                HEEL
              }
            ')

            type = document.definitions.first
            assert_equal GraphQL::Language::Nodes::EnumTypeDefinition, type.class
            assert_equal 'DogCommand', type.name
            assert_equal 3, type.values.length

            assert_equal 'SIT', type.values[0].name
            assert_equal [], type.values[0].directives
            assert_equal "Good dog", type.values[0].description

            assert_equal 'DOWN', type.values[1].name
            assert_equal 1, type.values[1].directives.length
            deprecated_directive = type.values[1].directives[0]
            assert_equal 'deprecated', deprecated_directive.name
            assert_equal 'reason', deprecated_directive.arguments[0].name
            assert_equal 'No longer supported', deprecated_directive.arguments[0].value

            assert_equal 'HEEL', type.values[2].name
            assert_equal [], type.values[2].directives
          end

          def test_it_parses_input_types
            document = parse('
              input EmptyMutationInput {
                clientMutationId: String
              }
            ')

            type = document.definitions.first
            assert_equal GraphQL::Language::Nodes::InputObjectTypeDefinition, type.class
            assert_equal 'EmptyMutationInput', type.name
            assert_equal ['clientMutationId'], type.fields.map(&:name)
            assert_equal 'String', type.fields[0].type.name
            assert_equal nil, type.fields[0].default_value
          end

          def test_it_parses_directives
            document = parse('
              directive @include(if: Boolean!)
                on FIELD
                | FRAGMENT_SPREAD
                | INLINE_FRAGMENT
            ')

            type = document.definitions.first
            assert_equal GraphQL::Language::Nodes::DirectiveDefinition, type.class
            assert_equal 'include', type.name

            assert_equal 1, type.arguments.length
            assert_equal 'if', type.arguments[0].name
            assert_equal 'Boolean', type.arguments[0].type.of_type.name

            assert_equal ['FIELD', 'FRAGMENT_SPREAD', 'INLINE_FRAGMENT'], type.locations
          end

          def test_it_parses_field_arguments
            document = parse('
              type Mutation {
                post(
                  id: ID! @deprecated(reason: "Not used"),
                  # This is what goes in the post
                  data: String
                ): Post
              }
            ')

            field = document.definitions.first.fields.first
            assert_equal ['id', 'data'], field.arguments.map(&:name)
            id_arg = field.arguments[0]

            deprecated_directive = id_arg.directives[0]
            assert_equal 'deprecated', deprecated_directive.name
            assert_equal 'reason', deprecated_directive.arguments[0].name
            assert_equal 'Not used', deprecated_directive.arguments[0].value

            data_arg = field.arguments[1]
            assert_equal "data", data_arg.name
            assert_equal "This is what goes in the post", data_arg.description
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

            brand_field = interface_type_definition.fields[1]
            assert_equal 1, brand_field.arguments.length
            assert_equal 'argument', brand_field.arguments[0].name
            assert_instance_of GraphQL::Language::Nodes::NullValue, brand_field.arguments[0].default_value
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
          brand(argument: String = null): String!
        }

        # Comment at the end of schema
      |
    end
  end
end
