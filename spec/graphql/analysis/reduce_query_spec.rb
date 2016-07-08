require "spec_helper"

describe GraphQL::Analysis do
  class TypeCollector < GraphQL::Analysis::Reducer
    def initial_value(query)
      []
    end

    def before_operation_definition(memo, type_env, node, prev_node)
      memo + [type_env.current_type_definition]
    end

    def before_field(memo, type_env, node, prev_node)
      memo + [type_env.current_type_definition]
    end
  end

  describe ".reduce_query" do
    let(:node_counter) {
      -> (memo, visit_type, type_env, node, prev_node) {
        memo ||= Hash.new { |h,k| h[k] = 0 }
        visit_type == :enter && memo[node.class] += 1
        memo
      }
    }
    let(:type_collector) { TypeCollector.new }
    let(:reducers) { [type_collector, node_counter] }
    let(:reduce_result) { GraphQL::Analysis.reduce_query(query, reducers) }
    let(:query) { GraphQL::Query.new(DummySchema, query_string) }
    let(:query_string) {%|
      {
        cheese(id: 1) {
          id
          flavor
        }
      }
    |}

    it "calls the defined reducers" do
      collected_types, node_counts = reduce_result
      expected_visited_types = [QueryType, CheeseType, GraphQL::INT_TYPE, GraphQL::STRING_TYPE]
      assert_equal expected_visited_types, collected_types
      expected_node_counts = {
        GraphQL::Language::Nodes::Document => 1,
        GraphQL::Language::Nodes::OperationDefinition => 1,
        GraphQL::Language::Nodes::Field => 3,
        GraphQL::Language::Nodes::Argument => 1
      }
      assert_equal expected_node_counts, node_counts
    end
  end
end
