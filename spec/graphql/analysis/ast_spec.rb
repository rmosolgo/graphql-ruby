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
        query_analyzer AstErrorAnalyzer
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
  end

  describe ".analyze_query" do
    let(:analyzers) { [AstTypeCollector, AstNodeCounter] }
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

    class FinishedSchema < GraphQL::Schema
      class FinishedAnalyzer < GraphQL::Analysis::AST::Analyzer
        def on_enter_field(node, parent, visitor)
          if query.context[:force_prepare]
            visitor.arguments_for(node, visitor.field_definition)
          end
        end

        def result
          query.context[:analysis_finished] = true
        end
      end

      class Query < GraphQL::Schema::Object
        field :f1, Int do
          argument :arg, String, prepare: ->(val, ctx) {
            ctx[:analysis_finished] ? val.to_i : raise("Prepared too soon!")
          }
        end
        def f1(arg:)
          arg
        end
      end

      query(Query)

      query_analyzer(FinishedAnalyzer)
    end

    it "doesn't call prepare hooks by default" do
      res = FinishedSchema.execute("{ f1(arg: \"5\") }")
      assert_equal 5, res["data"]["f1"]
      err = assert_raises RuntimeError do
        FinishedSchema.execute("{ f1(arg: \"5\") }", context: { force_prepare: true })
      end
      assert_equal "Prepared too soon!", err.message
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

  describe "Detecting all-introspection queries" do
    class AllIntrospectionSchema < GraphQL::Schema
      class Query < GraphQL::Schema::Object
        field :int, Int
      end
      query(Query)
    end

    class AllIntrospectionAnalyzer < GraphQL::Analysis::AST::Analyzer
      def initialize(query)
        @is_introspection = true
        super
      end

      def on_enter_field(node, parent, visitor)
        @is_introspection &= (visitor.field_definition.introspection? || ((owner = visitor.field_definition.owner) && owner.introspection?))
      end

      def result
        @is_introspection
      end
    end

    def is_introspection?(query_str)
      query = GraphQL::Query.new(AllIntrospectionSchema, query_str)
      result = GraphQL::Analysis::AST.analyze_query(query, [AllIntrospectionAnalyzer])
      result.first
    end

    it "returns true for queries containing only introspection types and fields" do
      assert is_introspection?("{ __typename }")
      refute is_introspection?("{ int }")
      assert is_introspection?(GraphQL::Introspection::INTROSPECTION_QUERY)
      assert is_introspection?("{ __type(name: \"Something\") { fields { name } } }")
      refute is_introspection?("{ int __type(name: \"Thing\") { name } }")
    end
  end

  describe "when there's a hidden field" do
    class HiddenAnalyzedFieldSchema < GraphQL::Schema
      class DoNothingAnalyzer < GraphQL::Analysis::AST::Analyzer
        def on_enter_field(node, parent, visitor)
          @result ||= []
          @result << [node.name, visitor.field_definition.class]
          super
        end

        def result
          @result
        end
      end
      class BaseField < GraphQL::Schema::Field
        def initialize(*args, visible: true, **kwargs, &block)
          @visible = visible
          super(*args, **kwargs, &block)
        end

        def visible?(context)
          return @visible
        end
      end

      class BaseObject < GraphQL::Schema::Object
        field_class BaseField
      end

      class Article < BaseObject
        field :title, String, null: false
      end

      class Query < BaseObject
        field :article, String, visible: false do |f|
          f.argument(:id, Integer)
        end

        def article(id:)
          { title: "hello world" }
        end
      end

      query Query
    end

    it "uses nil for the field definition" do
      gql = <<~GQL
      {
        article(id: 1) {
          title
        }
      }
      GQL

      query = GraphQL::Query.new(HiddenAnalyzedFieldSchema, gql)
      result = GraphQL::Analysis::AST.analyze_query(query, [HiddenAnalyzedFieldSchema::DoNothingAnalyzer])
      assert_equal [[["article", NilClass], ["title", NilClass]]], result
    end
  end
end
