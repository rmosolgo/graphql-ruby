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
        GraphQL::Deprecation.warn "#{self} will be removed from GraphQL-Ruby 2.0. There is no replacement, please open an issue on GitHub if you need support."

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

          def test_it_parses_union_types
            document = parse(
              "union BagOfThings = \n" \
              "A |\n" \
              "B |\n" \
              "C"
            )

            union = document.definitions.first

            assert_equal GraphQL::Language::Nodes::UnionTypeDefinition, union.class
            assert_equal 'BagOfThings', union.name
            assert_equal 3, union.types.length
            assert_equal [1, 1], union.position

            assert_equal GraphQL::Language::Nodes::TypeName, union.types[0].class
            assert_equal 'A', union.types[0].name
            assert_equal [2, 1], union.types[0].position

            assert_equal GraphQL::Language::Nodes::TypeName, union.types[1].class
            assert_equal 'B', union.types[1].name
            assert_equal [3, 1], union.types[1].position

            assert_equal GraphQL::Language::Nodes::TypeName, union.types[2].class
            assert_equal 'C', union.types[2].name
            assert_equal [4, 1], union.types[2].position
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

            assert_equal 3, type.locations.length

            assert_instance_of GraphQL::Language::Nodes::DirectiveLocation, type.locations[0]
            assert_equal 'FIELD', type.locations[0].name
            assert_equal [3, 20], type.locations[0].position

            assert_instance_of GraphQL::Language::Nodes::DirectiveLocation, type.locations[1]
            assert_equal 'FRAGMENT_SPREAD', type.locations[1].name
            assert_equal [4, 19], type.locations[1].position

            assert_instance_of GraphQL::Language::Nodes::DirectiveLocation, type.locations[2]
            assert_equal 'INLINE_FRAGMENT', type.locations[2].name
            assert_equal [5, 19], type.locations[2].position
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

          def test_it_parses_schema_extensions
            document = parse('
              extend schema {
                query: QueryRoot
                mutation: MutationRoot
                subscription: SubscriptionRoot
              }
            ')

            schema_extension = document.definitions.first
            assert_equal GraphQL::Language::Nodes::SchemaExtension, schema_extension.class
            assert_equal [2, 15], schema_extension.position

            assert_equal 'QueryRoot', schema_extension.query
            assert_equal 'MutationRoot', schema_extension.mutation
            assert_equal 'SubscriptionRoot', schema_extension.subscription
          end

          def test_it_parses_schema_extensions_with_directives
            document = parse('
              extend schema @something {
                query: QueryRoot
              }
            ')

            schema_extension = document.definitions.first
            assert_equal GraphQL::Language::Nodes::SchemaExtension, schema_extension.class

            assert_equal 1, schema_extension.directives.length
            assert_equal GraphQL::Language::Nodes::Directive, schema_extension.directives.first.class
            assert_equal 'something', schema_extension.directives.first.name

            assert_equal 'QueryRoot', schema_extension.query
            assert_equal nil, schema_extension.mutation
            assert_equal nil, schema_extension.subscription
          end

          def test_it_parses_schema_extensions_with_only_directives
            document = parse('
              extend schema @something
            ')

            schema_extension = document.definitions.first
            assert_equal GraphQL::Language::Nodes::SchemaExtension, schema_extension.class

            assert_equal 1, schema_extension.directives.length
            assert_equal GraphQL::Language::Nodes::Directive, schema_extension.directives.first.class
            assert_equal 'something', schema_extension.directives.first.name

            assert_equal nil, schema_extension.query
            assert_equal nil, schema_extension.mutation
            assert_equal nil, schema_extension.subscription
          end

          def test_it_parses_scalar_extensions
            document = parse('
              extend scalar Date @something @somethingElse
            ')

            scalar_extension = document.definitions.first
            assert_equal GraphQL::Language::Nodes::ScalarTypeExtension, scalar_extension.class
            assert_equal 'Date', scalar_extension.name
            assert_equal [2, 15], scalar_extension.position

            assert_equal 2, scalar_extension.directives.length
            assert_equal GraphQL::Language::Nodes::Directive, scalar_extension.directives.first.class
            assert_equal 'something', scalar_extension.directives.first.name
            assert_equal GraphQL::Language::Nodes::Directive, scalar_extension.directives.last.class
            assert_equal 'somethingElse', scalar_extension.directives.last.name
          end

          def test_it_parses_object_type_extensions_with_field_definitions
            document = parse('
              extend type User {
                login: String!
              }
            ')

            object_type_extension = document.definitions.first
            assert_equal GraphQL::Language::Nodes::ObjectTypeExtension, object_type_extension.class
            assert_equal 'User', object_type_extension.name
            assert_equal [2, 15], object_type_extension.position

            assert_equal 1, object_type_extension.fields.length
            assert_equal GraphQL::Language::Nodes::FieldDefinition, object_type_extension.fields.first.class
          end

          def test_it_parses_object_type_extensions_with_field_definitions_and_directives
            document = parse('
              extend type User @deprecated {
                login: String!
              }
            ')

            object_type_extension = document.definitions.first
            assert_equal GraphQL::Language::Nodes::ObjectTypeExtension, object_type_extension.class
            assert_equal 'User', object_type_extension.name
            assert_equal [2, 15], object_type_extension.position

            assert_equal 1, object_type_extension.fields.length
            assert_equal GraphQL::Language::Nodes::FieldDefinition, object_type_extension.fields.first.class

            assert_equal 1, object_type_extension.directives.length
            assert_equal GraphQL::Language::Nodes::Directive, object_type_extension.directives.first.class
          end

          def test_it_parses_object_type_extensions_with_field_definitions_and_implements
            document = parse('
              extend type User implements Node {
                login: String!
              }
            ')

            object_type_extension = document.definitions.first
            assert_equal GraphQL::Language::Nodes::ObjectTypeExtension, object_type_extension.class
            assert_equal 'User', object_type_extension.name
            assert_equal [2, 15], object_type_extension.position

            assert_equal 1, object_type_extension.fields.length
            assert_equal GraphQL::Language::Nodes::FieldDefinition, object_type_extension.fields.first.class

            assert_equal 1, object_type_extension.interfaces.length
            assert_equal GraphQL::Language::Nodes::TypeName, object_type_extension.interfaces.first.class
          end

          def test_it_parses_object_type_extensions_with_only_directives
            document = parse('
              extend type User @deprecated
            ')

            object_type_extension = document.definitions.first
            assert_equal GraphQL::Language::Nodes::ObjectTypeExtension, object_type_extension.class
            assert_equal 'User', object_type_extension.name
            assert_equal [2, 15], object_type_extension.position

            assert_equal 1, object_type_extension.directives.length
            assert_equal GraphQL::Language::Nodes::Directive, object_type_extension.directives.first.class
            assert_equal 'deprecated', object_type_extension.directives.first.name
          end

          def test_it_parses_object_type_extensions_with_implements_and_directives
            document = parse('
              extend type User implements Node @deprecated
            ')

            object_type_extension = document.definitions.first
            assert_equal GraphQL::Language::Nodes::ObjectTypeExtension, object_type_extension.class
            assert_equal 'User', object_type_extension.name
            assert_equal [2, 15], object_type_extension.position

            assert_equal 1, object_type_extension.directives.length
            assert_equal GraphQL::Language::Nodes::Directive, object_type_extension.directives.first.class
            assert_equal 'deprecated', object_type_extension.directives.first.name

            assert_equal 1, object_type_extension.interfaces.length
            assert_equal GraphQL::Language::Nodes::TypeName, object_type_extension.interfaces.first.class
            assert_equal 'Node', object_type_extension.interfaces.first.name
          end

          def test_it_parses_object_type_extensions_with_only_implements
            document = parse('
              extend type User implements Node
            ')

            object_type_extension = document.definitions.first
            assert_equal GraphQL::Language::Nodes::ObjectTypeExtension, object_type_extension.class
            assert_equal 'User', object_type_extension.name
            assert_equal [2, 15], object_type_extension.position

            assert_equal 1, object_type_extension.interfaces.length
            assert_equal GraphQL::Language::Nodes::TypeName, object_type_extension.interfaces.first.class
            assert_equal 'Node', object_type_extension.interfaces.first.name
          end

          def test_it_parses_interface_type_extensions_with_directives_and_fields
            document = parse('
              extend interface Node @directive {
                field: String
              }
            ')

            interface_type_extension = document.definitions.first
            assert_equal GraphQL::Language::Nodes::InterfaceTypeExtension, interface_type_extension.class
            assert_equal 'Node', interface_type_extension.name
            assert_equal [2, 15], interface_type_extension.position

            assert_equal 1, interface_type_extension.directives.length
            assert_equal GraphQL::Language::Nodes::Directive, interface_type_extension.directives.first.class
            assert_equal 'directive', interface_type_extension.directives.first.name

            assert_equal 1, interface_type_extension.fields.length
            assert_equal GraphQL::Language::Nodes::FieldDefinition, interface_type_extension.fields.first.class
            assert_equal 'field', interface_type_extension.fields.first.name
          end

          def test_it_parses_interface_type_extensions_with_fields
            document = parse('
              extend interface Node {
                field: String
              }
            ')

            interface_type_extension = document.definitions.first
            assert_equal GraphQL::Language::Nodes::InterfaceTypeExtension, interface_type_extension.class
            assert_equal 'Node', interface_type_extension.name
            assert_equal [2, 15], interface_type_extension.position

            assert_equal 0, interface_type_extension.directives.length

            assert_equal 1, interface_type_extension.fields.length
            assert_equal GraphQL::Language::Nodes::FieldDefinition, interface_type_extension.fields.first.class
            assert_equal 'field', interface_type_extension.fields.first.name
          end

          def test_it_parses_interface_type_extensions_with_directives
            document = parse('
              extend interface Node @directive
            ')

            interface_type_extension = document.definitions.first
            assert_equal GraphQL::Language::Nodes::InterfaceTypeExtension, interface_type_extension.class
            assert_equal 'Node', interface_type_extension.name
            assert_equal [2, 15], interface_type_extension.position

            assert_equal 1, interface_type_extension.directives.length
            assert_equal GraphQL::Language::Nodes::Directive, interface_type_extension.directives.first.class
            assert_equal 'directive', interface_type_extension.directives.first.name
          end

          def test_it_parses_union_type_extension_with_union_members
            document = parse('
              extend union BagOfThings = A | B
            ')

            union_type_extension = document.definitions.first
            assert_equal GraphQL::Language::Nodes::UnionTypeExtension, union_type_extension.class
            assert_equal 'BagOfThings', union_type_extension.name
            assert_equal [2, 15], union_type_extension.position

            assert_equal 0, union_type_extension.directives.length

            assert_equal 2, union_type_extension.types.length
            assert_equal GraphQL::Language::Nodes::TypeName, union_type_extension.types.first.class
            assert_equal 'A', union_type_extension.types.first.name
          end

          def test_it_parses_union_type_extension_with_directives_and_union_members
            document = parse('
              extend union BagOfThings @directive = A | B
            ')

            union_type_extension = document.definitions.first
            assert_equal GraphQL::Language::Nodes::UnionTypeExtension, union_type_extension.class
            assert_equal 'BagOfThings', union_type_extension.name
            assert_equal [2, 15], union_type_extension.position

            assert_equal 1, union_type_extension.directives.length
            assert_equal GraphQL::Language::Nodes::Directive, union_type_extension.directives.first.class
            assert_equal 'directive', union_type_extension.directives.first.name

            assert_equal 2, union_type_extension.types.length
            assert_equal GraphQL::Language::Nodes::TypeName, union_type_extension.types.first.class
            assert_equal 'A', union_type_extension.types.first.name
          end

          def test_it_parses_union_type_extension_with_directives
            document = parse('
              extend union BagOfThings @directive
            ')

            union_type_extension = document.definitions.first
            assert_equal GraphQL::Language::Nodes::UnionTypeExtension, union_type_extension.class
            assert_equal 'BagOfThings', union_type_extension.name
            assert_equal [2, 15], union_type_extension.position

            assert_equal 1, union_type_extension.directives.length
            assert_equal GraphQL::Language::Nodes::Directive, union_type_extension.directives.first.class
            assert_equal 'directive', union_type_extension.directives.first.name

            assert_equal 0, union_type_extension.types.length
          end

          def test_it_parses_enum_type_extension_with_values
            document = parse('
              extend enum Status {
                DRAFT
                PUBLISHED
              }
            ')

            enum_type_extension = document.definitions.first
            assert_equal GraphQL::Language::Nodes::EnumTypeExtension, enum_type_extension.class
            assert_equal 'Status', enum_type_extension.name
            assert_equal [2, 15], enum_type_extension.position

            assert_equal 0, enum_type_extension.directives.length

            assert_equal 2, enum_type_extension.values.length
            assert_equal GraphQL::Language::Nodes::EnumValueDefinition, enum_type_extension.values.first.class
            assert_equal 'DRAFT', enum_type_extension.values.first.name
          end

          def test_it_parses_enum_type_extension_with_directives_and_values
            document = parse('
              extend enum Status @directive {
                DRAFT
                PUBLISHED
              }
            ')

            enum_type_extension = document.definitions.first
            assert_equal GraphQL::Language::Nodes::EnumTypeExtension, enum_type_extension.class
            assert_equal 'Status', enum_type_extension.name
            assert_equal [2, 15], enum_type_extension.position

            assert_equal 1, enum_type_extension.directives.length
            assert_equal GraphQL::Language::Nodes::Directive, enum_type_extension.directives.first.class
            assert_equal 'directive', enum_type_extension.directives.first.name

            assert_equal 2, enum_type_extension.values.length
            assert_equal GraphQL::Language::Nodes::EnumValueDefinition, enum_type_extension.values.first.class
            assert_equal 'DRAFT', enum_type_extension.values.first.name
          end

          def test_it_parses_enum_type_extension_with_directives
            document = parse('
              extend enum Status @directive
            ')

            enum_type_extension = document.definitions.first
            assert_equal GraphQL::Language::Nodes::EnumTypeExtension, enum_type_extension.class
            assert_equal 'Status', enum_type_extension.name
            assert_equal [2, 15], enum_type_extension.position

            assert_equal 1, enum_type_extension.directives.length
            assert_equal GraphQL::Language::Nodes::Directive, enum_type_extension.directives.first.class
            assert_equal 'directive', enum_type_extension.directives.first.name

            assert_equal 0, enum_type_extension.values.length
          end

          def test_it_parses_input_object_type_extension_with_fields
            document = parse('
              extend input UserInput {
                login: String!
              }
            ')

            input_object_type_extension = document.definitions.first
            assert_equal GraphQL::Language::Nodes::InputObjectTypeExtension, input_object_type_extension.class
            assert_equal 'UserInput', input_object_type_extension.name
            assert_equal [2, 15], input_object_type_extension.position

            assert_equal 1, input_object_type_extension.fields.length
            assert_equal GraphQL::Language::Nodes::InputValueDefinition, input_object_type_extension.fields.first.class
            assert_equal 'login', input_object_type_extension.fields.first.name

            assert_equal 0, input_object_type_extension.directives.length
          end

          def test_it_parses_input_object_type_extension_with_directives_and_fields
            document = parse('
              extend input UserInput @deprecated {
                login: String!
              }
            ')

            input_object_type_extension = document.definitions.first
            assert_equal GraphQL::Language::Nodes::InputObjectTypeExtension, input_object_type_extension.class
            assert_equal 'UserInput', input_object_type_extension.name
            assert_equal [2, 15], input_object_type_extension.position

            assert_equal 1, input_object_type_extension.fields.length
            assert_equal GraphQL::Language::Nodes::InputValueDefinition, input_object_type_extension.fields.first.class
            assert_equal 'login', input_object_type_extension.fields.first.name

            assert_equal 1, input_object_type_extension.directives.length
            assert_equal GraphQL::Language::Nodes::Directive, input_object_type_extension.directives.first.class
            assert_equal 'deprecated', input_object_type_extension.directives.first.name
          end

          def test_it_parses_input_object_type_extension_with_directives
            document = parse('
              extend input UserInput @deprecated
            ')

            input_object_type_extension = document.definitions.first
            assert_equal GraphQL::Language::Nodes::InputObjectTypeExtension, input_object_type_extension.class
            assert_equal 'UserInput', input_object_type_extension.name
            assert_equal [2, 15], input_object_type_extension.position

            assert_equal 0, input_object_type_extension.fields.length

            assert_equal 1, input_object_type_extension.directives.length
            assert_equal GraphQL::Language::Nodes::Directive, input_object_type_extension.directives.first.class
            assert_equal 'deprecated', input_object_type_extension.directives.first.name
          end

          def test_it_parses_whole_definition_with_descriptions
            document = parse(SCHEMA_DEFINITION_STRING)

            assert_equal 6, document.definitions.size

            schema_definition, directive_definition, enum_type_definition, object_type_definition, input_object_type_definition, interface_type_definition = document.definitions

            assert_equal GraphQL::Language::Nodes::SchemaDefinition, schema_definition.class

            assert_equal GraphQL::Language::Nodes::DirectiveDefinition, directive_definition.class
            assert_equal 'This is a directive', directive_definition.description

            assert_equal GraphQL::Language::Nodes::EnumTypeDefinition, enum_type_definition.class
            assert_equal "Multiline comment\n\nWith an enum", enum_type_definition.description

            assert_nil enum_type_definition.values[0].description
            assert_equal 'Not a creative color', enum_type_definition.values[1].description

            assert_equal GraphQL::Language::Nodes::ObjectTypeDefinition, object_type_definition.class
            assert_equal 'Comment without preceding space', object_type_definition.description
            assert_equal 'And a field to boot', object_type_definition.fields[0].description

            assert_equal GraphQL::Language::Nodes::InputObjectTypeDefinition, input_object_type_definition.class
            assert_equal 'Comment for input object types', input_object_type_definition.description
            assert_equal 'Color of the car', input_object_type_definition.fields[0].description

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
