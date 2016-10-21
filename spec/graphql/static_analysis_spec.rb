require "spec_helper"

describe GraphQL::StaticAnalysis do
  include StaticAnalysisHelpers

  def assert_errors_without_schema(query_string, *error_messages)
    assert_errors(query_string, *error_messages, schema: nil)
  end

  describe "kitchen sink" do
    it "finds every error"
  end

  describe "arguments" do
    it "requires unique names per-field" do
      query_string = %|
      {
        b(a: 1, a: 2, b: 1)
        a(a: 1, b: 1) @directive(c: 1, c: 2, c: 3, d: 4)
      }|

      assert_errors_without_schema(
        query_string,
        'Arguments must be unique, but "a" is provided 2 times',
        'Arguments must be unique, but "c" is provided 3 times',
      )
    end

    it "requires unique names on nested inputs" do
      query_string = %|
      {
        field(input: {nested: {a: 1, a: 2, a: 3}})
      }|

      assert_errors_without_schema(
        query_string,
        'Arguments must be unique, but "a" is provided 3 times',
      )
    end
  end

  describe "fragments" do
    it "checks for infinite loops" do
      query_string = %|
      query getStuff { ... frag1 }
      query getStuff2 { ... frag2 }
      query getStuff3 { thisIsOk }
      fragment frag1 on Type { ... frag2 }
      fragment frag2 on Type { ... frag3 }
      fragment frag3 on Type { ... frag1 }
      |

      assert_errors_without_schema(query_string, "Some definitions contain cycles: getStuff, getStuff2, frag1, frag2, frag3")
    end

    it "requires unique names" do
      query_string = %|
      { ...frag1 }
      fragment frag1 on Type { stuff }
      fragment frag1 on Type { things }
      |
      assert_errors_without_schema(query_string, "Fragment names must be unique, but frag1 is not unique")
    end

    it "requires spreads to have definitions" do
      query_string = %|
      { ...frag1 ...frag2 ...frag3 }
      fragment frag1 on Type { stuff }
      fragment frag2 on Type { things }
      |
      assert_errors_without_schema(query_string, "Query uses undefined fragments: frag3")
    end

    it "requires definitions to be used" do
      query_string = %|
      { ...frag1 ...frag3 }
      fragment frag1 on Type { stuff }
      fragment frag2 on Type { things }
      fragment frag3 on Type { something }
      fragment frag4 on Type { something }
      |
      assert_errors_without_schema(query_string, "Fragments are defined but unused: frag4, frag2")
    end

  end

  describe "variables" do
    it "requires unique variables" do
      query_string = %|
        query getStuff($a: Int, $b: Int, $b: Int) {
          stuff(a: $a, b: $b)
        }
      |
      assert_errors_without_schema(query_string, "Variable name must be unique: $b")
    end

    it "requires variables to be used" do
      query_string = %|
        query getStuff($a: Int = 4) {
          stuff
        }

        query getStuff2($a: Int = 4) {
          ...stuffFields
        }

        fragment stuffFields on StuffType {
          stuff(a: $a)
        }
      |

      assert_errors_without_schema(query_string, "Variable must be used: $a")
    end

    it "requires variables to be defined" do
      query_string = %|
        query getStuff($a: Int = 4, $c: String!) {
          ... stuffFields
        }

        query getStuff2($a: Int, $b: String) {
          ... stuffFields
        }

        fragment stuffFields on StuffType {
          stuff(a: $a, b: $b, c: $c)
        }
      |
      assert_errors_without_schema(
        query_string,
        "Variable must be defined: $b",
        "Variable must be defined: $c",
      )
    end
  end

  describe "operation names" do
    it "requires unique operation names" do
      query_string = %|
        query FirstQuery { stuff }
        query SecondQuery { stuff }
      |
      assert_errors_without_schema(query_string) # none

      query_string = %|
        query FirstQuery { stuff }
        query FirstQuery { stuff }
        query SecondQuery { stuff }
        query SecondQuery { stuff }
        query ThirdQuery { stuff }
      |

      assert_errors_without_schema(
        query_string,
        "Operation names must be unique, but FirstQuery is not unique",
        "Operation names must be unique, but SecondQuery is not unique",
      )
    end

    it "allows one anonymous operation" do
      assert_errors_without_schema("{ stuff }") # none
      assert_errors_without_schema("{ stuff } { things }", "A document must not have more than one anonymous operation")
    end

    it "doesn't allow anonymous and named operations" do
      query_string = "{ stuff } query Things { things }"
      assert_errors_without_schema(query_string, "A document must not mix anonymous operations with named operations")
    end
  end
end
