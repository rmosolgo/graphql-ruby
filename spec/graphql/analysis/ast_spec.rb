# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Analysis::AST do
  class TypeCollector < GraphQL::Analysis::Analyzer
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

  class NodeCounter < GraphQL::Analysis::Analyzer
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

  class ConditionalAnalyzer < GraphQL::Analysis::Analyzer
    def initialize(query)
      @i_have_been_called = false
    end

    def analyze?(query)
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

    focus
    it "calls the defined analyzers" do
      collected_types, node_counts = reduce_result
      expected_visited_types = [Dummy::DairyAppQueryType, Dummy::CheeseType, GraphQL::INT_TYPE, GraphQL::STRING_TYPE]
      assert_equal expected_visited_types, collected_types
      expected_node_counts = {
        GraphQL::Language::Nodes::OperationDefinition => 1,
        GraphQL::Language::Nodes::Field => 3,
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

    describe "when a variable is missing" do
      let(:query_string) {%|
        query something($cheeseId: Int!){
          cheese(id: $cheeseId) {
            id
            flavor
          }
        }
      |}
      let(:variable_accessor) { ->(memo, visit_type, irep_node) { query.variables["cheeseId"] } }

      before do
        @previous_query_analyzers = Dummy::Schema.query_analyzers.dup
        Dummy::Schema.query_analyzers.clear
        Dummy::Schema.query_analyzers << variable_accessor
      end

      after do
        Dummy::Schema.query_analyzers.clear
        Dummy::Schema.query_analyzers.push(*@previous_query_analyzers)
      end

      it "returns an error" do
        error = query.result["errors"].first
        assert_equal "Variable cheeseId of type Int! was provided invalid value", error["message"]
      end
    end

    describe "when processing fields" do
      let(:connection_counter) {
        ->(memo, visit_type, irep_node) {
          memo ||= Hash.new { |h,k| h[k] = 0 }
          if visit_type == :enter
            if irep_node.ast_node.is_a?(GraphQL::Language::Nodes::Field)
              if irep_node.definition.connection?
                memo[:connection] ||= 0
                memo[:connection] += 1
              else
                memo[:field] ||= 0
                memo[:field] += 1
              end
            end
          end
          memo
        }
      }
      let(:analyzers) { [connection_counter] }
      let(:reduce_result) { GraphQL::Analysis.analyze_query(query, analyzers) }
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
          :field => 5,
          :connection => 2
        }
        assert_equal expected_connection_counts, connection_counts
      end
    end
  end
end
