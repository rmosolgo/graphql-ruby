require "spec_helper"

describe GraphQL::StaticAnalysis::VariableUsages do
  def get_usages(query_string)
    document = GraphQL.parse(query_string)
    visitor = GraphQL::Language::Visitor.new(document)
    variable_usages = GraphQL::StaticAnalysis::VariableUsages.mount(visitor)
    deps = GraphQL::StaticAnalysis::DefinitionDependencies.mount(visitor)
    visitor.visit
    variable_usages.usages(dependencies: deps.dependency_map)
  end

  describe "usages" do
    let(:query_string) {%|
    query First($a: Int, $b: Int, $b: Int) {
      field(a: $a)
      ... frag1
      field3(c: $c)
    }

    fragment frag1 on Type { ... frag2 }
    fragment frag2 on Type { field2(a: $a, b: $b) }
    |}

    it "tracks operation definitions only" do
      assert_equal ["First"], get_usages(query_string).keys.map(&:name)
    end

    it "records usages" do
      usages = get_usages(query_string).values.first[:used]
      assert_equal 2, usages["a"].length
      assert_equal [[3, 16],[9, 40]], usages["a"].map { |n| [n.line, n.col] }
      assert_equal 1, usages["c"].length
    end

    it "records definitions" do
      definitions = get_usages(query_string).values.first[:defined]
      assert_equal 2, definitions.length
      assert_equal [[2, 17]], definitions["a"].map { |n| [n.line, n.col] }
      assert_equal 2, definitions["b"].length
    end

    it "handles anonymous definitions" do
      assert get_usages("{ stuff, things } { otherStuff }")
    end
  end
end
