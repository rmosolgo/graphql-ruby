require 'spec_helper'

describe GraphQL::Language::Parser do
  let(:document) { GraphQL::Language::Parser.parse(query_string) }
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

  describe '.parse' do
    let(:_query_string) { '
        query getStuff($fragment: Int!, $false: String = "h\"😸i") @skip(ok: 1) {
          myField(
            arg1: 4.5,
            arg2: -3,
            arg3: "hello ☀︎ \uD83C\uDF40",
            arg4: 4.5e-12,
            arg5: true
            arg6: $false
            arg7: [true, false],
            arg8: {key: "val", ok: true, whatever: $fragment}
            arg9: ENUM_VALUE
          ) {
            aliasName: childField @skip(on: true)
            ... description
          },
          # Comment!
          #
          otherField
        }

        fragment thingStuff on Thing {
          whatever
        }
      '}

    it 'parses queries' do
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
        assert_equal [2, 5], [query.line, query.col]
      end

      it "creates a valid fragment definition" do
        assert fragment_def.is_a?(GraphQL::Language::Nodes::FragmentDefinition)
        assert_equal "moreNestedFields", fragment_def.name
        assert_equal 1, fragment_def.selections.length
        assert_equal "NestedType", fragment_def.type
        assert_equal 1, fragment_def.directives.length
        assert_equal [20, 5], fragment_def.position
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
          assert_equal [2, 20], optional_var.position
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
          assert_equal [3 ,7], leaf_field.position
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
          assert_equal [3, 26], variable_argument.position
        end
      end

      describe "fragment spreads" do
        let(:fragment_spread) { query.selections[1].selections.last }
        it "gets the name and directives" do
          assert_equal "moreNestedFields", fragment_spread.name
          assert_equal 1, fragment_spread.directives.length
        end

        it "gets position info" do
          assert_equal [7, 9], fragment_spread.position
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
          assert_equal [3, 54], variable_directive.position
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
          assert_equal [10, 7], inline_fragment.position
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
  end

  describe "errors" do
    let(:query_string) {%| query doSomething { bogus { } |}
    it "raises a parse error" do
      err = assert_raises(GraphQL::ParseError) { document }
    end

    it 'correctly identifies parse error location and content' do
      e = assert_raises(GraphQL::ParseError) do
        GraphQL.parse("
          query getCoupons {
            allCoupons: {data{id}}
          }
        ")
      end
      assert_includes(e.message, '"{"')
      assert_includes(e.message, "RCURLY")
      assert_equal(3, e.line)
      assert_equal(25, e.col)
    end

    it "handles unexpected ends" do
      err = assert_raises { GraphQL.parse("{ ") }
      assert_equal "Unexpected end of document", err.message
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
