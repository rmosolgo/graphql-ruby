require "spec_helper"

describe GraphQL::StaticAnalysis::DefinitionDependencies do
  def find_dependencies(query_string)
    document = GraphQL.parse(query_string)
    visitor = GraphQL::Language::Visitor.new(document)
    definition_dependencies = GraphQL::StaticAnalysis::DefinitionDependencies.mount(visitor)
    visitor.visit
    definition_dependencies
  end

  def find_deps_by_name(dep_hash, operation_name)
    op_defn = dep_hash.keys.find { |defn| defn.name == operation_name }
    dep_hash[op_defn]
  end

  def find_unmet_deps_by_name(dep_hash, operation_name)
    op_defn = dep_hash.unmet_dependencies.keys.find { |defn| defn.name == operation_name }
    dep_hash.unmet_dependencies[op_defn]
  end

  describe "#definition_hash" do
    let(:query_string) {%|
      query First { ...frag1 ...frag2 }
      query Second { a, b }
      # Infinite:
      query Third { ...frag5 }
      # Unmet:
      query Fourth { ...frag1 ...frag7 }

      fragment frag1 on Type { ... frag3 }
      fragment frag2 on Type { something }
      fragment frag3 on Type { ... frag4 }
      fragment frag4 on Type { somethingElse }

      # Infinite Fragments
      fragment frag5 on Type { ... frag6 }
      fragment frag6 on Type { ... frag5 }

      # Unused Fragments
      fragment frag8 on Type { ... frag2 }
      fragment frag9 on Type { stuff }
    |}

    it "maps definitions to their dependencies" do
      deps_map = find_dependencies(query_string).dependency_map

      first_deps = find_deps_by_name(deps_map, "First")
      assert_equal(["frag1", "frag2", "frag3", "frag4"], first_deps.map(&:name).sort)

      second_deps = find_deps_by_name(deps_map, "Second")
      assert_equal([], second_deps)

      fragment_deps = find_deps_by_name(deps_map, "frag1")
      assert_equal(["frag3", "frag4"], fragment_deps.map(&:name).sort)
    end

    it "finds cyclical dependencies" do
      deps_map = find_dependencies(query_string).dependency_map

      cycles = deps_map.cyclical_definitions
      assert_equal(["Third", "frag5", "frag6"], cycles.map(&:name))
    end

    it "finds unmet dependencies" do
      deps_map = find_dependencies(query_string).dependency_map
      unmet_deps = find_unmet_deps_by_name(deps_map, "Fourth")
      assert_equal(["frag7"], unmet_deps.map(&:name))
    end

    it "finds unused dependencies" do
      deps_map = find_dependencies(query_string).dependency_map
      unused_deps = deps_map.unused_dependencies
      assert_equal(["frag8", "frag9"], unused_deps.map(&:name).sort)
    end
  end
end
