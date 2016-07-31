require "spec_helper"

describe GraphQL::Analysis do
  class TypeCollector
    def initial_value(query)
      []
    end

    def call(memo, visit_type, irep_node)
      if visit_type == :enter
        memo + [irep_node.return_type]
      else
        memo
      end
    end
  end

  describe ".analyze_query" do
    let(:node_counter) {
      -> (memo, visit_type, irep_node) {
        memo ||= Hash.new { |h,k| h[k] = 0 }
        visit_type == :enter && memo[irep_node.ast_node.class] += 1
        memo
      }
    }
    let(:type_collector) { TypeCollector.new }
    let(:analyzers) { [type_collector, node_counter] }
    let(:reduce_result) { GraphQL::Analysis.analyze_query(query, analyzers) }
    let(:query) { GraphQL::Query.new(DummySchema, query_string) }
    let(:query_string) {%|
      {
        cheese(id: 1) {
          id
          flavor
        }
      }
    |}

    it "calls the defined analyzers" do
      collected_types, node_counts = reduce_result
      expected_visited_types = [DairyAppQueryType, CheeseType, GraphQL::INT_TYPE, GraphQL::STRING_TYPE]
      assert_equal expected_visited_types, collected_types
      expected_node_counts = {
        GraphQL::Language::Nodes::OperationDefinition => 1,
        GraphQL::Language::Nodes::Field => 3,
      }
      assert_equal expected_node_counts, node_counts
    end
  end
end
