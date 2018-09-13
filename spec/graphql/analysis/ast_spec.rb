# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Analysis::AST do
  class TypeCollector < GraphQL::Analysis::AST::Analyzer
    def initialize(query)
      super
      @types = []
    end

    def on_enter_operation_definition(node, parent, visitor)
      @types << visitor.type_definition
    end

    def on_enter_field(memo, node, visitor)
      @types << visitor.field_definition.type.unwrap
    end

    def result
      @types
    end
  end

  class NodeCounter < GraphQL::Analysis::AST::Analyzer
    def initialize(query)
      super
      @nodes = Hash.new { |h,k| h[k] = 0 }
    end

    def on_enter_abstract_node(node, parent, _visitor)
      @nodes[node.class] += 1
    end

    def result
      @nodes
    end
  end

  class ConditionalAnalyzer < GraphQL::Analysis::AST::Analyzer
    def initialize(query)
      super
      @i_have_been_called = false
    end

    def analyze?
      !!query.context[:analyze]
    end

    def on_operation_definition(node, parent, visitor)
      @i_have_been_called = true
    end

    def result
      @i_have_been_called
    end
  end

  describe ".analyze_query" do
    let(:analyzers) { [TypeCollector, NodeCounter] }
    let(:reduce_result) { GraphQL::Analysis::AST.analyze_query(query, analyzers) }
    let(:variables) { {} }
    let(:query) { GraphQL::Query.new(Dummy::Schema, query_string, variables: variables) }
    let(:query_string) {%|
      {
        cheese(id: 1) {
          id
          flavor
        }
      }
    |}

    describe "conditional analysis" do
      let(:analyzers) { [TypeCollector, ConditionalAnalyzer] }

      describe "when analyze? returns false" do
        let(:query) { GraphQL::Query.new(Dummy::Schema, query_string, variables: variables, context: { analyze: false }) }

        it "does not run the analyzer" do
          # Only type_collector ran
          assert_equal 1, reduce_result.size
        end
      end

      describe "when analyze? returns true" do
        let(:query) { GraphQL::Query.new(Dummy::Schema, query_string, variables: variables, context: { analyze: true }) }

        it "it runs the analyzer" do
          # Both analyzers ran
          assert_equal 2, reduce_result.size
        end
      end
    end

    it "calls the defined analyzers" do
      collected_types, node_counts = reduce_result
      expected_visited_types = [
        Dummy::DairyAppQuery.graphql_definition,
        Dummy::Cheese.graphql_definition,
        GraphQL::INT_TYPE,
        GraphQL::STRING_TYPE
      ]
      assert_equal expected_visited_types, collected_types

      expected_node_counts = {
        GraphQL::Language::Nodes::Document => 1,
        GraphQL::Language::Nodes::OperationDefinition => 1,
        GraphQL::Language::Nodes::Field => 3,
        GraphQL::Language::Nodes::Argument => 1
      }

      assert_equal expected_node_counts, node_counts
    end

    describe "tracing" do
      let(:query_string) { "{ t: __typename }"}

      it "emits traces" do
        traces = TestTracing.with_trace do
          ctx = { tracers: [TestTracing] }
          Dummy::Schema.execute(query_string, context: ctx)
        end

        # The query_trace is on the list _first_ because it finished first
        _lex, _parse, _validate, query_trace, multiplex_trace, *_rest = traces

        assert_equal "analyze_multiplex", multiplex_trace[:key]
        assert_instance_of GraphQL::Execution::Multiplex, multiplex_trace[:multiplex]

        assert_equal "analyze_query", query_trace[:key]
        assert_instance_of GraphQL::Query, query_trace[:query]
      end
    end

    class ConnectionCounter < GraphQL::Analysis::AST::Analyzer
      def initialize(query)
        super
        @fields = 0
        @connections = 0
      end

      def on_enter_field(node, parent, visitor)
        if visitor.field_definition.connection?
          @connections += 1
        else
          @fields += 1
        end
      end

      def result
        {
          fields: @fields,
          connections: @connections
        }
      end
    end

    describe "when processing fields" do
      let(:analyzers) { [ConnectionCounter] }
      let(:reduce_result) { GraphQL::Analysis::AST.analyze_query(query, analyzers) }
      let(:query) { GraphQL::Query.new(StarWars::Schema, query_string, variables: variables) }
      let(:query_string) {%|
        query getBases {
          empire {
            basesByName(first: 30) { edges { cursor } }
            bases(first: 30) { edges { cursor } }
          }
        }
      |}

      it "knows which fields are connections" do
        connection_counts = reduce_result.first
        expected_connection_counts = {
          :fields => 5,
          :connections => 2
        }
        assert_equal expected_connection_counts, connection_counts
      end
    end
  end
end
