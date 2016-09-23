require "spec_helper"

describe GraphQL::Language::Generation do
  let(:document) { GraphQL::Language::Parser.parse(query_string) }
  let(:query_string) {%|
    query getStuff($someVar: Int = 1, $anotherVar: [String!], $skipNested: Boolean! = false) @skip(if: false) {
      myField: someField(someArg: $someVar, ok: 1.4) @skip(if: $anotherVar) @thing(or: "Whatever")
      anotherField(someArg: [1, 2, 3]) {
        nestedField
        ...moreNestedFields @skip(if: $skipNested)
      }
      ... on OtherType @include(unless: false) {
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

  describe ".generate" do
    it "generates query string" do
      assert_equal query_string.gsub(/^    /, "").strip, document.to_query_string
    end

    describe "inputs" do
      let(:query_string) {%|
        query {
          field(int: 3, float: 4.7e-24, bool: false, string: "☀︎🏆\\n escaped \\" unicode ¶ /", enum: ENUM_NAME, array: [7, 8, 9], object: {a: [1, 2, 3], b: {c: "4"}}, unicode_bom: "\xef\xbb\xbfquery")
        }
      |}

      it "generate" do
        assert_equal query_string.gsub(/^        /, "").strip, document.to_query_string
      end
    end

    describe "schema" do
      # From: https://github.com/graphql/graphql-js/blob/a725499b155285c2e33647a93393c82689b20b0f/src/language/__tests__/schema-kitchen-sink.graphql
      let(:query_string) {<<-schema
        schema {
          query: QueryType
          mutation: MutationType
        }

        type Foo implements Bar {
          one: Type
          two(argument: InputType!): Type
          three(argument: InputType, other: String): Int
          four(argument: String = "string"): String
          five(argument: [String] = ["string", "string"]): String
          six(argument: InputType = {key: "value"}): Type
        }

        type AnnotatedObject @onObject(arg: "value") {
          annotatedField(arg: Type = "default" @onArg): Type @onField
        }

        interface Bar {
          one: Type
          four(argument: String = "string"): String
        }

        interface AnnotatedInterface @onInterface {
          annotatedField(arg: Type @onArg): Type @onField
        }

        union Feed = Story | Article | Advert

        union AnnotatedUnion @onUnion = A | B

        scalar CustomScalar

        scalar AnnotatedScalar @onScalar

        enum Site {
          DESKTOP
          MOBILE
        }

        enum AnnotatedEnum @onEnum {
          ANNOTATED_VALUE @onEnumValue
          OTHER_VALUE
        }

        input InputType {
          key: String!
          answer: Int = 42
        }

        input AnnotatedInput @onInputObjectType {
          annotatedField: Type @onField
        }
      schema
      }

      it "generate" do
        assert_equal query_string.gsub(/^        /, "").strip, document.to_query_string
      end

      it "doesn't mutate the document" do
        assert_equal document.to_query_string, document.to_query_string
      end
    end
  end
end
