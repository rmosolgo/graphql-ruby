require "spec_helper"

describe GraphQL::Language::Generation do
  let(:document) { GraphQL::Language::Parser.parse(query_string) }
  let(:query_string) {%|
    query getStuff($someVar: Int = 1, $anotherVar: [String!], $skipNested: Boolean! = false) @skip(if: false) {
      myField: someField(someArg: $someVar, ok: 1.4) @skip(if: $anotherVar) @thing(or: "Whatever")
      anotherField(someArg: [1, 2, 3]) {
        nestedField
        ... moreNestedFields @skip(if: $skipNested)
      }
      ... on OtherType @include(unless: false) {
        field(arg: [{ key: "value", anotherKey: 0.9, anotherAnotherKey: WHATEVER }])
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
          field(int: 3, float: 4.7e-24, bool: false, string: "☀︎🏆\\n escaped \\" unicode ¶ /", enum: ENUM_NAME, array: [7, 8, 9], object: { a: [1, 2, 3], b: { c: "4" } }, unicode_bom: "\xef\xbb\xbfquery")
        }
      |}

      it "generate" do
        assert_equal query_string.gsub(/^        /, "").strip, document.to_query_string
      end
    end
  end
end
