# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Analysis::AST do
  class AstTypeCollector < GraphQL::Analysis::AST::Analyzer
    def initialize(query, multiplex: nil)
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
    def initialize(query, multiplex: nil)
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
    def initialize(query, multiplex: nil)
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
    let(:schema) {
      schema = Class.new(Dummy::Schema)
      schema.analysis_engine = GraphQL::Analysis::AST
      schema
    }
    let(:analyzers) { [AstTypeCollector, AstNodeCounter] }
    let(:reduce_result) { GraphQL::Analysis::AST.analyze_query(query, analyzers) }
    let(:variables) { {} }
    let(:query) { GraphQL::Query.new(schema, query_string, variables: variables) }
    let(:query_string) {%|
      {
        cheese(id: 1) {
          id
          flavor
        }
      }
    |}

    describe "without a selected operation" do
      let(:query_string) {%|
        # A comment
        # And nothing else
        # Should not break
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
          assert_equal "__Schema.types", prev_field.metadata[:type_class].path
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
          assert_equal "DairyProductInput.source", argument.metadata[:type_class].path
          assert_equal "Query.searchDairy.product", prev_argument.metadata[:type_class].path
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

  describe ".analyze_multiplex" do
    # before do
    #   @old =  Dummy::Schema.analysis_engine
    #   Dummy::Schema.analysis_engine = GraphQL::Analysis::AST
    # end
    # after do
    #   Dummy::Schema.analysis_engine = @old
    # end
    let(:schema) {
      schema = Class.new(Dummy::Schema)
      schema.analysis_engine = GraphQL::Analysis::AST
      schema
    }
    let(:variables) { {} }
    let(:query) {
      GraphQL::Query.new(
        schema,
        query_string,
        variables: variables
      )
    }
    let(:analyzers) { [AstTypeCollector, AstNodeCounter] }
    let(:multiplex) {
      GraphQL::Execution::Multiplex.new(
        schema: schema,
        queries: [query.dup, query.dup],
        context: {},
        max_complexity: 10
      )
    }
    let(:reduce_multiplex_result) { GraphQL::Analysis::AST.analyze_multiplex(multiplex, analyzers) }

    let(:query_string) {%|
      {
        cheese(id: 1) {
          id
          flavor
        }
      }
    |}

    describe "when analyzer has an error" do
      let(:analyzers) { [AstErrorAnalyzer] }
      it "it is attached to all query objects anaylzer errors set" do
        reduce_multiplex_result
        error_set = multiplex.queries.map(&:analysis_errors)
        assert_equal 2, error_set.size
        error = error_set.first.first
        assert_equal "An Error!", error.message
      end
    end

    describe "when there are multiple queries in a multiplex" do
      class QueryChange < GraphQL::Analysis::AST::Analyzer
        def initialize(query, multiplex: true)
          super
          @query_change = 0
        end

        def set_current_query(query)
          super
          @query_change += 1
        end

        def result
          @query_change
        end
      end


      let(:analyzers) { [QueryChange] }
      it "each query is passed to the multiplex anaylzer" do
        assert_equal 2, reduce_multiplex_result.first
      end
    end

    describe "invalid queries" do
      let(:query_string) { %|
        {
          invalid_query {
            id
            flavor
          }
        }
      |}
      it "do not run analyzers" do
        assert_equal true, reduce_multiplex_result.first.empty?
        assert_equal true, reduce_multiplex_result.last.empty?
      end
    end

    describe "conditional analysis" do
      let(:analyzers) { [AstTypeCollector, AstConditionalAnalyzer] }

      describe "when analyze? returns false" do
        let(:query) { GraphQL::Query.new(schema, query_string, variables: variables, context: { analyze: false }) }

        it "does not run the analyzer" do
          # Only type_collector ran
          assert_equal 1, reduce_multiplex_result.size
        end
      end

      describe "when analyze? returns true" do
        let(:query) { GraphQL::Query.new(schema, query_string, variables: variables, context: { analyze: true }) }

        it "it runs the multiplex analyzer" do
          assert_equal 2, reduce_multiplex_result.size
        end
      end
    end
  end
end
