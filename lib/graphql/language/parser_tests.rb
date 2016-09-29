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
          let(:query_string) {%|
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
              anotherNestedField
            }
          |}

          describe ".parse" do
            it "parses queries" do
              assert document
            end

            describe "visited nodes" do
              let(:query) { document.definitions.first }
              let(:fragment_def) { document.definitions.last }

              it "creates a valid document" do
                assert document.is_a?(GraphQL::Language::Nodes::Document)
                assert_equal 2, document.definitions.length
              end

              it "creates a valid operation" do
                assert query.is_a?(GraphQL::Language::Nodes::OperationDefinition)
                assert_equal "getStuff", query.name
                assert_equal "query", query.operation_type
                assert_equal 2, query.variables.length
                assert_equal 4, query.selections.length
                assert_equal 1, query.directives.length
                assert_equal [2, 13], [query.line, query.col]
              end

              it "creates a valid fragment definition" do
                assert fragment_def.is_a?(GraphQL::Language::Nodes::FragmentDefinition)
                assert_equal "moreNestedFields", fragment_def.name
                assert_equal 1, fragment_def.selections.length
                assert_equal "NestedType", fragment_def.type
                assert_equal 1, fragment_def.directives.length
                assert_equal [20, 13], fragment_def.position
              end

              describe "variable definitions" do
                let(:optional_var) { query.variables.first }
                it "gets name and type" do
                  assert_equal "someVar", optional_var.name
                  assert_equal "Int", optional_var.type.name
                end

                it "gets default value" do
                  assert_equal 1, optional_var.default_value
                end

                it "gets position info" do
                  assert_equal [2, 28], optional_var.position
                end
              end

              describe "fields" do
                let(:leaf_field) { query.selections.first }
                let(:parent_field) { query.selections[1] }

                it "gets name, alias, arguments and directives" do
                  assert_equal "someField", leaf_field.name
                  assert_equal "myField", leaf_field.alias
                  assert_equal 2, leaf_field.directives.length
                  assert_equal 2, leaf_field.arguments.length
                end

                it "gets nested fields" do
                  assert_equal 2, parent_field.selections.length
                end

                it "gets location info" do
                  assert_equal [3 ,15], leaf_field.position
                end

                describe "when the arguments list is empty" do
                  let(:query_string) { "{ field() }"}
                  let(:field) { query.selections.first }
                  it "has zero arguments" do
                    assert_equal 0, field.arguments.length
                  end
                end

                describe "when selections are empty" do
                  let(:query_string) { "{ field { } }"}
                  let(:field) { query.selections.first }
                  it "has zero selections" do
                    assert_equal 0, field.selections.length
                  end
                end
              end

              describe "arguments" do
                let(:literal_argument) { query.selections.first.arguments.last }
                let(:variable_argument) { query.selections.first.arguments.first }

                it "gets name and literal value" do
                  assert_equal "ok", literal_argument.name
                  assert_equal 1.4, literal_argument.value
                end

                it "gets name and variable value" do
                  assert_equal "someArg", variable_argument.name
                  assert_equal "someVar", variable_argument.value.name
                end


                it "gets position info" do
                  assert_equal [3, 34], variable_argument.position
                end
              end

              describe "fragment spreads" do
                let(:fragment_spread) { query.selections[1].selections.last }
                it "gets the name and directives" do
                  assert_equal "moreNestedFields", fragment_spread.name
                  assert_equal 1, fragment_spread.directives.length
                end

                it "gets position info" do
                  assert_equal [7, 17], fragment_spread.position
                end
              end

              describe "directives" do
                let(:variable_directive) { query.selections.first.directives.first }

                it "gets the name and arguments" do
                  assert_equal "skip", variable_directive.name
                  assert_equal "if", variable_directive.arguments.first.name
                  assert_equal 1, variable_directive.arguments.length
                end

                it "gets position info" do
                  assert_equal [3, 62], variable_directive.position
                end
              end

              describe "inline fragments" do
                let(:inline_fragment) { query.selections[2] }
                let(:typeless_inline_fragment) { query.selections[3] }

                it "gets the type and directives" do
                  assert_equal "OtherType", inline_fragment.type
                  assert_equal 2, inline_fragment.selections.length
                  assert_equal 1, inline_fragment.directives.length
                end

                it "gets inline fragments without type conditions" do
                  assert_equal nil, typeless_inline_fragment.type
                  assert_equal 1, typeless_inline_fragment.selections.length
                  assert_equal 0, typeless_inline_fragment.directives.length
                end

                it "gets position info" do
                  assert_equal [10, 15], inline_fragment.position
                end
              end

              describe "inputs" do
                let(:query_string) {%|
                  {
                    field(
                      int: 3,
                      float: 4.7e-24,
                      bool: false,
                      string: "☀︎🏆\\n escaped \\" unicode \\u00b6 /",
                      enum: ENUM_NAME,
                      array: [7, 8, 9]
                      object: {a: [1,2,3], b: {c: "4"}}
                      unicode_bom: "\xef\xbb\xbfquery"
                      keywordEnum: on
                    )
                  }
                |}

                let(:inputs) { document.definitions.first.selections.first.arguments }

                it "parses ints" do
                  assert_equal 3, inputs[0].value
                end

                it "parses floats" do
                  assert_equal 0.47e-23, inputs[1].value
                end

                it "parses booleans" do
                  assert_equal false, inputs[2].value
                end

                it "parses UTF-8 strings" do
                  assert_equal %|☀︎🏆\n escaped " unicode ¶ /|, inputs[3].value
                end

                it "parses enums" do
                  assert_instance_of GraphQL::Language::Nodes::Enum, inputs[4].value
                  assert_equal "ENUM_NAME", inputs[4].value.name
                end

                it "parses arrays" do
                  assert_equal [7,8,9], inputs[5].value
                end

                it "parses objects" do
                  obj = inputs[6].value
                  assert_equal "a", obj.arguments[0].name
                  assert_equal [1,2,3], obj.arguments[0].value
                  assert_equal "b", obj.arguments[1].name
                  assert_equal "c", obj.arguments[1].value.arguments[0].name
                  assert_equal "4", obj.arguments[1].value.arguments[0].value
                end

                it "parses unicode bom" do
                  obj = inputs[7].value
                  assert_equal %|\xef\xbb\xbfquery|, inputs[7].value
                end

                it "parses enum 'on''" do
                  assert_equal "on", inputs[8].value.name
                end
              end
            end

            describe "unnamed queries" do
              let(:query_string) {%|
                { name, age, height }
              |}
              let(:operation) { document.definitions.first }

              it "parses unnamed queries" do
                assert_equal 1, document.definitions.length
                assert_equal "query", operation.operation_type
                assert_equal nil, operation.name
                assert_equal 3, operation.selections.length
              end
            end

            describe "introspection query" do
              let(:query_string) { GraphQL::Introspection::INTROSPECTION_QUERY }

              it "parses a big ol' query" do
                assert(document)
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
                assert_equal ['Node'], type.interfaces
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
                assert_equal ['Node'], type.interfaces
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

          describe "errors" do
            let(:query_string) {%| query doSomething { bogus { } |}
            it "raises a parse error" do
              err = assert_raises(GraphQL::ParseError) { document }
            end

            it "correctly identifies parse error location and content" do
              e = assert_raises(GraphQL::ParseError) do
                GraphQL.parse("
                  query getCoupons {
                    allCoupons: {data{id}}
                  }
                ")
              end
              assert_includes(e.message, '"{"')
              assert_includes(e.message, "LCURLY")
              assert_equal(3, e.line)
              assert_equal(33, e.col)
            end

            it "handles unexpected ends" do
              err = assert_raises(GraphQL::ParseError) { GraphQL.parse("{ ") }
              assert_equal "Unexpected end of document", err.message
            end

            it "rejects unsupported characters" do
              e = assert_raises(GraphQL::ParseError) do
                GraphQL.parse("{ field; }")
              end

              assert_includes(e.message, "Parse error on \";\"")
            end

            it "rejects control characters" do
              e = assert_raises(GraphQL::ParseError) do
                GraphQL.parse("{ \afield }")
              end

              assert_includes(e.message, "Parse error on \"\\a\"")
            end

            it "rejects partial BOM" do
              e = assert_raises(GraphQL::ParseError) do
                GraphQL.parse("{ \xeffield }")
              end

              assert_includes(e.message, "Parse error on \"\\xEF\"")
            end

            it "rejects vertical tabs" do
              e = assert_raises(GraphQL::ParseError) do
                GraphQL.parse("{ \vfield }")
              end

              assert_includes(e.message, "Parse error on \"\\v\"")
            end

            it "rejects form feed" do
              e = assert_raises(GraphQL::ParseError) do
                GraphQL.parse("{ \ffield }")
              end

              assert_includes(e.message, "Parse error on \"\\f\"")
            end

            it "rejects no break space" do
              e = assert_raises(GraphQL::ParseError) do
                GraphQL.parse("{ \xa0field }")
              end

              assert_includes(e.message, "Parse error on \"\\xA0\"")
            end

            it "rejects unterminated strings" do
              e = assert_raises(GraphQL::ParseError) do
                GraphQL.parse("\"")
              end

              assert_includes(e.message, "Parse error on \"\\\"\"")

              e = assert_raises(GraphQL::ParseError) do
                GraphQL.parse("\"\n\"")
              end

              assert_includes(e.message, "Parse error on \"\\n\"")
            end

            it "rejects bad escape sequence in strings" do
              e = assert_raises(GraphQL::ParseError) do
                GraphQL.parse("{ field(arg:\"\\x\") }")
              end

              assert_includes(e.message, "Parse error on bad Unicode escape sequence")
            end

            it "rejects incomplete escape sequence in strings" do
              e = assert_raises(GraphQL::ParseError) do
                GraphQL.parse("{ field(arg:\"\\u1\") }")
              end

              assert_includes(e.message, "bad Unicode escape sequence")
            end

            it "rejects unicode escape with bad chars" do
              e = assert_raises(GraphQL::ParseError) do
                GraphQL.parse("{ field(arg:\"\\u0XX1\") }")
              end

              assert_includes(e.message, "bad Unicode escape sequence")

              e = assert_raises(GraphQL::ParseError) do
                GraphQL.parse("{ field(arg:\"\\uXXXX\") }")
              end

              assert_includes(e.message, "bad Unicode escape sequence")


              e = assert_raises(GraphQL::ParseError) do
                GraphQL.parse("{ field(arg:\"\\uFXXX\") }")
              end

              assert_includes(e.message, "bad Unicode escape sequence")


              e = assert_raises(GraphQL::ParseError) do
                GraphQL.parse("{ field(arg:\"\\uXXXF\") }")
              end

              assert_includes(e.message, "bad Unicode escape sequence")
            end

            it "rejects fragments named 'on'" do
              e = assert_raises(GraphQL::ParseError) do
                GraphQL.parse("fragment on on on { on }")
              end

              assert_includes(e.message, "Parse error on \"on\"")
            end

            it "rejects fragment spread of 'on'" do
              e = assert_raises(GraphQL::ParseError) do
                GraphQL.parse("{ ...on }")
              end

              assert_includes(e.message, "Parse error on \"}\"")
            end

            it "rejects null value" do
              e = assert_raises(GraphQL::ParseError) do
                GraphQL.parse("{ fieldWithNullableStringInput(input: null) }")
              end

              assert_includes(e.message, "Parse error on \"null\"")
            end
          end


          describe "whitespace" do
            describe "whitespace-only queries" do
              let(:query_string) { " " }
              it "doesn't blow up" do
                assert_equal [], document.definitions
              end
            end

            describe "empty string queries" do
              let(:query_string) { "" }
              it "doesn't blow up" do
                assert_equal [], document.definitions
              end
            end

            describe "using tabs as whitespace" do
              let(:query_string) { "\t{\t\tid, \tname}"}
              it "parses the query" do
                assert_equal 1, document.definitions.length
              end
            end
          end
        end
      end
    end
  end
end
