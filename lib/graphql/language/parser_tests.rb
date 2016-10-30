module GraphQL
  module Language
    # If you create your own GraphQL parser, can verify it using these tests.
    #
    # @example Include these tests in a Minitest suite
    #   require 'graphql/language/parser_tests'
    #
    #   describe MyParser do
    #     include GraphQL::Language::ParserTests
    #     subject { MyParser }
    #   end
    module ParserTests
      def self.included(test)
        test.send(:describe, "Parser Tests") do
          let(:document) { subject.parse(query_string) }

          describe ".parse" do
            describe "schema with comments" do
              let(:query_string) {%|
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
              |}

              it "parses successfully" do
                document = subject.parse(query_string)

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

            describe "schema" do
              it "parses the test schema" do
                schema = DummySchema
                schema_string = GraphQL::Schema::Printer.print_schema(schema)

                document = subject.parse(schema_string)

                assert_equal schema_string, document.to_query_string
              end

              it "parses mimal schema definition" do
                document = subject.parse('schema { query: QueryRoot }')

                schema = document.definitions.first
                assert_equal 'QueryRoot', schema.query
                assert_equal nil, schema.mutation
                assert_equal nil, schema.subscription
              end

              it "parses full schema definitions" do
                document = subject.parse('
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

              it "parses object types" do
                document = subject.parse('
                  type Comment implements Node {
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
              end

              it "parses object types with directives" do
                document = subject.parse('
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

              it "parses field arguments" do
                document = subject.parse('
                  type Mutation {
                    post(id: ID!, data: PostData = { message: "First!1!", type: BLOG, tags: ["Test", "Annoying"] }): Post
                  }
                ')

                field = document.definitions.first.fields.first
                assert_equal ['id', 'data'], field.arguments.map(&:name)
                data_arg = field.arguments[1]
                assert_equal 'PostData', data_arg.type.name
                assert_equal ['message', 'type', 'tags'], data_arg.default_value.arguments.map(&:name)
                tags_arg = data_arg.default_value.arguments[2]
                assert_equal ['Test', 'Annoying'], tags_arg.value
              end

              it "parses field arguments with directives" do
                document = subject.parse('
                  type Mutation {
                    post(id: ID! @deprecated(reason: "No longer supported"), data: String): Post
                  }
                ')

                field = document.definitions.first.fields.first
                assert_equal ['id', 'data'], field.arguments.map(&:name)
                id_arg = field.arguments[0]

                deprecated_directive = id_arg.directives[0]
                assert_equal 'deprecated', deprecated_directive.name
                assert_equal 'reason', deprecated_directive.arguments[0].name
                assert_equal 'No longer supported', deprecated_directive.arguments[0].value
              end

              it "parses directive definition" do
                document = subject.parse('
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

              it "parses scalar types" do
                document = subject.parse('scalar DateTime')

                type = document.definitions.first
                assert_equal GraphQL::Language::Nodes::ScalarTypeDefinition, type.class
                assert_equal 'DateTime', type.name
              end

              it "parses scalar types with directives" do
                document = subject.parse('scalar DateTime @deprecated(reason: "No longer supported")')

                type = document.definitions.first
                assert_equal GraphQL::Language::Nodes::ScalarTypeDefinition, type.class
                assert_equal 'DateTime', type.name
                assert_equal 1, type.directives.length

                deprecated_directive = type.directives[0]
                assert_equal 'deprecated', deprecated_directive.name
                assert_equal 'reason', deprecated_directive.arguments[0].name
                assert_equal 'No longer supported', deprecated_directive.arguments[0].value
              end

              it "parses interface types" do
                document = subject.parse('
                  interface Node {
                    id: ID!
                  }
                ')

                type = document.definitions.first
                assert_equal GraphQL::Language::Nodes::InterfaceTypeDefinition, type.class
                assert_equal 'Node', type.name
                assert_equal ['id'], type.fields.map(&:name)
                assert_equal [], type.fields[0].arguments
                assert_equal 'ID', type.fields[0].type.of_type.name
              end

              it "parses interface types with directives" do
                document = subject.parse('
                  interface Node @deprecated(reason: "No longer supported") {
                    id: ID!
                  }
                ')

                type = document.definitions.first
                assert_equal GraphQL::Language::Nodes::InterfaceTypeDefinition, type.class
                assert_equal 'Node', type.name
                assert_equal 1, type.directives.length

                deprecated_directive = type.directives[0]
                assert_equal 'deprecated', deprecated_directive.name
                assert_equal 'reason', deprecated_directive.arguments[0].name
                assert_equal 'No longer supported', deprecated_directive.arguments[0].value
              end

              it "parses enum types" do
                document = subject.parse('
                  enum DogCommand {
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

                assert_equal 'DOWN', type.values[1].name
                assert_equal 1, type.values[1].directives.length
                deprecated_directive = type.values[1].directives[0]
                assert_equal 'deprecated', deprecated_directive.name
                assert_equal 'reason', deprecated_directive.arguments[0].name
                assert_equal 'No longer supported', deprecated_directive.arguments[0].value

                assert_equal 'HEEL', type.values[2].name
                assert_equal [], type.values[2].directives
              end

              it "parses enum types with directives" do
                document = subject.parse('
                  enum DogCommand @deprecated(reason: "No longer supported") {
                    SIT
                  }
                ')

                type = document.definitions.first
                assert_equal GraphQL::Language::Nodes::EnumTypeDefinition, type.class
                assert_equal 'DogCommand', type.name
                assert_equal 1, type.directives.length

                deprecated_directive = type.directives[0]
                assert_equal 'deprecated', deprecated_directive.name
                assert_equal 'reason', deprecated_directive.arguments[0].name
                assert_equal 'No longer supported', deprecated_directive.arguments[0].value
              end

              it "parses input object types" do
                document = subject.parse('
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

              it "parses input object types with directives" do
                document = subject.parse('
                  input EmptyMutationInput @deprecated(reason: "No longer supported") {
                    clientMutationId: String
                  }
                ')

                type = document.definitions.first
                assert_equal GraphQL::Language::Nodes::InputObjectTypeDefinition, type.class
                assert_equal 'EmptyMutationInput', type.name
                assert_equal ['clientMutationId'], type.fields.map(&:name)
                assert_equal 'String', type.fields[0].type.name
                assert_equal nil, type.fields[0].default_value
                assert_equal 1, type.directives.length

                deprecated_directive = type.directives[0]
                assert_equal 'deprecated', deprecated_directive.name
                assert_equal 'reason', deprecated_directive.arguments[0].name
                assert_equal 'No longer supported', deprecated_directive.arguments[0].value

              end
            end
          end
        end
      end
    end
  end
end
