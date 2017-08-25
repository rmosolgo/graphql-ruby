# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Analysis do
  class TypeCollector
    def initial_value(query)
      []
    end

    def call(memo, visit_type, irep_node)
      if visit_type == :enter
        memo + [irep_node.return_type.unwrap]
      else
        memo
      end
    end
  end

  describe ".analyze_query" do
    let(:node_counter) {
      ->(memo, visit_type, irep_node) {
        memo ||= Hash.new { |h,k| h[k] = 0 }
        visit_type == :enter && memo[irep_node.ast_node.class] += 1
        memo
      }
    }
    let(:type_collector) { TypeCollector.new }
    let(:analyzers) { [type_collector, node_counter] }
    let(:reduce_result) { GraphQL::Analysis.analyze_query(query, analyzers) }
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
          Dummy::Schema.execute(document: GraphQL.parse(query_string))
        end

        # The query_trace is on the list _first_ because it finished first
        _lex, _parse, _validate, query_trace, multiplex_trace, *_rest = traces

        assert_equal "analyze.multiplex", multiplex_trace[:key]
        assert_instance_of GraphQL::Execution::Multiplex, multiplex_trace[:multiplex]

        assert_equal "analyze.query", query_trace[:key]
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

  describe ".visit_analyzers" do
    class IdCatcher
      def call(memo, visit_type, irep_node)
        if visit_type == :enter
          if irep_node.ast_node.name == "id"
            raise GraphQL::AnalysisError.new("Don't use the id field.", ast_node: irep_node.ast_node)
          end
        end
        memo
      end
    end

    class FlavorCatcher
      def initial_value(query)
        {
          :errors => []
        }
      end

      def call(memo, visit_type, irep_node)
        if visit_type == :enter
          if irep_node.ast_node.name == "flavor"
            memo[:errors] << GraphQL::AnalysisError.new("Don't use the flavor field.", ast_node: irep_node.ast_node)
          end
        end
        memo
      end

      def final_value(memo)
        memo[:errors]
      end
    end

    let(:id_catcher) { IdCatcher.new }
    let(:flavor_catcher) { FlavorCatcher.new }
    let(:analyzers) { [id_catcher, flavor_catcher] }
    let(:reduce_result) { GraphQL::Analysis.analyze_query(query, analyzers) }
    let(:query) { GraphQL::Query.new(Dummy::Schema, query_string) }
    let(:query_string) {%|
      {
        cheese(id: 1) {
          id
          flavor
        }
      }
    |}
    let(:schema) { Dummy::Schema }
    let(:result) { schema.execute(query_string) }
    let(:query_string) {%|
      {
        cheese(id: 1) {
          id
          flavor
        }
      }
    |}

    before do
      @previous_query_analyzers = Dummy::Schema.query_analyzers.dup
      Dummy::Schema.query_analyzers.clear
      Dummy::Schema.query_analyzers << id_catcher << flavor_catcher
    end

    after do
      Dummy::Schema.query_analyzers.clear
      Dummy::Schema.query_analyzers.push(*@previous_query_analyzers)
    end

    it "groups all errors together" do
      data = result["data"]
      errors = result["errors"]

      id_error_hash = errors[0]
      flavor_error_hash = errors[1]

      id_error_response = {
        "message"=>"Don't use the id field.",
        "locations"=>[{"line"=>4, "column"=>11}]
      }
      flavor_error_response = {
        "message"=>"Don't use the flavor field.",
        "locations"=>[{"line"=>5, "column"=>11}]
      }

      assert_nil data

      assert_equal id_error_response["message"], id_error_hash["message"]
      assert_equal id_error_response["locations"], id_error_hash["locations"]

      assert_equal flavor_error_response["message"], flavor_error_hash["message"]
      assert_equal flavor_error_response["locations"], flavor_error_hash["locations"]
    end
  end
end
