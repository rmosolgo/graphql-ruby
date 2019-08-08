# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Analysis::AST do
  class AstTypeCollector < GraphQL::Analysis::AST::Analyzer
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

  class AstNodeCounter < GraphQL::Analysis::AST::Analyzer
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

  class AstConditionalAnalyzer < GraphQL::Analysis::AST::Analyzer
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

  class AstErrorAnalyzer < GraphQL::Analysis::AST::Analyzer
    def result
      GraphQL::AnalysisError.new("An Error!")
    end
  end

  class AstPreviousField < GraphQL::Analysis::AST::Analyzer
    def on_enter_field(node, parent, visitor)
      @previous_field = visitor.previous_field_definition
    end

    def result
      @previous_field
    end
  end

  class AstArguments < GraphQL::Analysis::AST::Analyzer
    def on_enter_argument(node, parent, visitor)
      @argument = visitor.argument_definition
      @previous_argument = visitor.previous_argument_definition
    end

    def result
      [@argument, @previous_argument]
    end
  end

  describe "using the AST analysis engine" do
    let(:schema) do
      query_type = Class.new(GraphQL::Schema::Object) do
        graphql_name 'Query'

        field :foobar, Integer, null: false

        def foobar
          1337
        end
      end

      Class.new(GraphQL::Schema) do
        query query_type
        use GraphQL::Analysis::AST
        query_analyzer AstErrorAnalyzer
        use GraphQL::Execution::Interpreter
      end
    end

    let(:query_string) {%|
      query {
        foobar
      }
    |}

    let(:query) { GraphQL::Query.new(schema, query_string, variables: {}) }

    it "runs the AST analyzers correctly" do
      res = query.result
      refute res.key?("data")
      assert_equal ["An Error!"], res["errors"].map { |e| e["message"] }
    end

    it "skips rewrite" do
      # Try running the query:
      query.result
      # But the validation step doesn't build an irep_node tree
      assert_nil query.irep_selection
    end

    describe "when validate: false" do
      let(:query) { GraphQL::Query.new(schema, query_string, validate: false) }
      it "Skips rewrite" do
        # Try running the query:
        query.result
        # But the validation step doesn't build an irep_node tree
        assert_nil query.irep_selection
      end
    end
  end

  describe ".analyze_query" do
    let(:analyzers) { [AstTypeCollector, AstNodeCounter] }
    let(:reduce_result) { GraphQL::Analysis::AST.analyze_query(query, analyzers) }
    let(:variables) { {} }
    let(:query) { GraphQL::Query.new(Dummy::Schema.graphql_definition, query_string, variables: variables) }
    let(:query_string) {%|
      {
        cheese(id: 1) {
          id
          flavor
        }
      }
    |}

    describe "without a valid operation" do
      let(:query_string) {%|
        # A comment
        # is an invalid operation
         # Should break
      |}

      it "bails early when there is no selected operation to be executed" do
        assert_equal 2, reduce_result.size
      end
    end

    describe "conditional analysis" do
      let(:analyzers) { [AstTypeCollector, AstConditionalAnalyzer] }

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

      describe "Visitor#previous_field_definition" do
        let(:analyzers) { [AstPreviousField] }
        let(:query) { GraphQL::Query.new(Dummy::Schema, "{ __schema { types { name } } }") }

        it "it runs the analyzer" do
          prev_field = reduce_result.first
          assert_equal "__Schema.types", prev_field.path
        end
      end

      describe "Visitor#argument_definition" do
        let(:analyzers) { [AstArguments] }
        let(:query) do
          GraphQL::Query.new(
            Dummy::Schema,
            '{ searchDairy(product: [{ source: "SHEEP" }]) { ... on Cheese { id } } }'
          )
        end

        it "it runs the analyzer" do
          argument, prev_argument = reduce_result.first
          assert_equal "DairyProductInput.source", argument.path
          assert_equal "Query.searchDairy.product", prev_argument.path
        end
      end
    end

    it "calls the defined analyzers" do
      collected_types, node_counts = reduce_result
      expected_visited_types = [
        Dummy::DairyAppQuery,
        Dummy::Cheese,
        GraphQL::Types::Int,
        GraphQL::Types::String
      ]
      assert_equal expected_visited_types, collected_types

      expected_node_counts = {
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

    class AstConnectionCounter < GraphQL::Analysis::AST::Analyzer
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
      let(:analyzers) { [AstConnectionCounter] }
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
