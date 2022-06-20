# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema do
  describe "inheritance" do
    class DummyFeature1 < GraphQL::Schema::Directive::Feature

    end

    class DummyFeature2 < GraphQL::Schema::Directive::Feature

    end

    class Query < GraphQL::Schema::Object
      field :some_field, String
    end

    class Mutation < GraphQL::Schema::Object
      field :some_field, String
    end

    class Subscription < GraphQL::Schema::Object
      field :some_field, String
    end

    class CustomSubscriptions < GraphQL::Subscriptions::ActionCableSubscriptions
    end

    let(:base_schema) do
      Class.new(GraphQL::Schema) do
        query Query
        mutation Mutation
        subscription Subscription
        max_complexity 1
        max_depth 2
        default_max_page_size 3
        default_page_size 2
        error_bubbling false
        disable_introspection_entry_points
        orphan_types Jazz::Ensemble
        introspection Module.new
        cursor_encoder Object.new
        query_execution_strategy Object.new
        mutation_execution_strategy Object.new
        subscription_execution_strategy Object.new
        context_class Class.new
        directives [DummyFeature1]
        tracer GraphQL::Tracing::DataDogTracing
        query_analyzer Object.new
        multiplex_analyzer Object.new
        rescue_from(StandardError) { }
        use GraphQL::Backtrace
        use GraphQL::Subscriptions::ActionCableSubscriptions, action_cable: nil, action_cable_coder: JSON
      end
    end

    it "inherits configuration from its superclass" do
      schema = Class.new(base_schema)
      assert_equal base_schema.query, schema.query
      assert_equal base_schema.mutation, schema.mutation
      assert_equal base_schema.subscription, schema.subscription
      assert_equal base_schema.introspection, schema.introspection
      assert_equal base_schema.cursor_encoder, schema.cursor_encoder
      assert_equal base_schema.query_execution_strategy, schema.query_execution_strategy
      assert_equal base_schema.mutation_execution_strategy, schema.mutation_execution_strategy
      assert_equal base_schema.subscription_execution_strategy, schema.subscription_execution_strategy
      assert_equal base_schema.validate_timeout, schema.validate_timeout
      assert_equal base_schema.max_complexity, schema.max_complexity
      assert_equal base_schema.max_depth, schema.max_depth
      assert_equal base_schema.default_max_page_size, schema.default_max_page_size
      assert_equal base_schema.default_page_size, schema.default_page_size
      assert_equal base_schema.error_bubbling, schema.error_bubbling
      assert_equal base_schema.orphan_types, schema.orphan_types
      assert_equal base_schema.context_class, schema.context_class
      assert_equal base_schema.directives, schema.directives
      assert_equal base_schema.tracers, schema.tracers
      assert_equal base_schema.query_analyzers, schema.query_analyzers
      assert_equal base_schema.multiplex_analyzers, schema.multiplex_analyzers
      assert_equal base_schema.disable_introspection_entry_points?, schema.disable_introspection_entry_points?
      assert_equal [GraphQL::Backtrace, GraphQL::Subscriptions::ActionCableSubscriptions], schema.plugins.map(&:first)
      assert_instance_of GraphQL::Subscriptions::ActionCableSubscriptions, schema.subscriptions
    end

    it "can override configuration from its superclass" do
      schema = Class.new(base_schema) do
        use CustomSubscriptions, action_cable: nil, action_cable_coder: JSON
      end

      query = Class.new(GraphQL::Schema::Object) do
        graphql_name 'Query'
        field :some_field, String
      end
      schema.query(query)
      mutation = Class.new(GraphQL::Schema::Object) do
        graphql_name 'Mutation'
        field :some_field, String
      end
      schema.mutation(mutation)
      subscription = Class.new(GraphQL::Schema::Object) do
        graphql_name 'Subscription'
        field :some_field, String
      end
      schema.subscription(subscription)
      introspection = Module.new
      schema.introspection(introspection)
      cursor_encoder = Object.new
      schema.cursor_encoder(cursor_encoder)
      query_execution_strategy = Object.new
      schema.query_execution_strategy(query_execution_strategy)
      mutation_execution_strategy = Object.new
      schema.mutation_execution_strategy(mutation_execution_strategy)
      subscription_execution_strategy = Object.new
      schema.subscription_execution_strategy(subscription_execution_strategy)
      assert_equal query_execution_strategy, schema.query_execution_strategy
      assert_equal mutation_execution_strategy, schema.mutation_execution_strategy
      assert_equal subscription_execution_strategy, schema.subscription_execution_strategy

      context_class = Class.new
      schema.context_class(context_class)
      schema.validate_timeout(10)
      schema.max_complexity(10)
      schema.max_depth(20)
      schema.default_max_page_size(30)
      schema.default_page_size(15)
      schema.error_bubbling(true)
      schema.orphan_types(Jazz::InstrumentType)
      schema.directives([DummyFeature2])
      query_analyzer = Object.new
      schema.query_analyzer(query_analyzer)
      multiplex_analyzer = Object.new
      schema.multiplex_analyzer(multiplex_analyzer)
      schema.rescue_from(GraphQL::ExecutionError)
      schema.tracer(GraphQL::Tracing::NewRelicTracing)

      assert_equal query, schema.query
      assert_equal mutation, schema.mutation
      assert_equal subscription, schema.subscription
      assert_equal introspection, schema.introspection
      assert_equal cursor_encoder, schema.cursor_encoder

      assert_equal context_class, schema.context_class
      assert_equal 10, schema.validate_timeout
      assert_equal 10, schema.max_complexity
      assert_equal 20, schema.max_depth
      assert_equal 30, schema.default_max_page_size
      assert_equal 15, schema.default_page_size
      assert schema.error_bubbling
      assert_equal [Jazz::Ensemble, Jazz::InstrumentType], schema.orphan_types
      assert_equal schema.directives, GraphQL::Schema.default_directives.merge(DummyFeature1.graphql_name => DummyFeature1, DummyFeature2.graphql_name => DummyFeature2)
      assert_equal base_schema.query_analyzers + [query_analyzer], schema.query_analyzers
      assert_equal base_schema.multiplex_analyzers + [multiplex_analyzer], schema.multiplex_analyzers
      assert_equal [GraphQL::Backtrace, GraphQL::Subscriptions::ActionCableSubscriptions, CustomSubscriptions], schema.plugins.map(&:first)
      assert_equal [GraphQL::Tracing::DataDogTracing, GraphQL::Backtrace::Tracer], base_schema.tracers
      assert_equal [GraphQL::Tracing::DataDogTracing, GraphQL::Backtrace::Tracer, GraphQL::Tracing::NewRelicTracing], schema.tracers
      assert_instance_of CustomSubscriptions, schema.subscriptions
    end
  end

  describe "merged, inherited caches" do
    METHODS_TO_CACHE = {
      types: 1,
      union_memberships: 1,
      references_to: 1,
      possible_types: 5, # The number of types with fields accessed in the query
    }

    let(:schema) do
      Class.new(Dummy::Schema) do
        def self.reset_calls
          @calls = Hash.new(0)
          @callers = Hash.new { |h, k| h[k] = [] }
        end

        METHODS_TO_CACHE.each do |method_name, allowed_calls|
          define_singleton_method(method_name) do |*args, &block|
            if @calls
              call_count = @calls[method_name] += 1
              @callers[method_name] << caller
            else
              call_count = 0
            end
            if call_count > allowed_calls
              raise "Called #{method_name} more than #{allowed_calls} times, previous caller: \n#{@callers[method_name].first.join("\n")}"
            end
            super(*args, &block)
          end
        end
      end
    end

    it "caches #{METHODS_TO_CACHE.keys} at runtime" do
      query_str = "
        query getFlavor($cheeseId: Int!) {
          brie: cheese(id: 1)   { ...cheeseFields, taste: flavor },
          cheese(id: $cheeseId)  {
            __typename,
            id,
            ...cheeseFields,
            ... edibleFields,
            ... on Cheese { cheeseKind: flavor },
          }
          fromSource(source: COW) { id }
          fromSheep: fromSource(source: SHEEP) { id }
          firstSheep: searchDairy(product: [{source: SHEEP}]) {
            __typename,
            ... dairyFields,
            ... milkFields
          }
          favoriteEdible { __typename, fatContent }
        }
        fragment cheeseFields on Cheese { flavor }
        fragment edibleFields on Edible { fatContent }
        fragment milkFields on Milk { source }
        fragment dairyFields on AnimalProduct {
           ... on Cheese { flavor }
           ... on Milk   { source }
        }
      "
      schema.reset_calls
      res = schema.execute(query_str,  variables: { cheeseId: 2 })
      assert_equal "Brie", res["data"]["brie"]["flavor"]
    end
  end

  describe "`use` works with plugins that attach instrumentation, tracers, query analyzers" do
    class NoOpTracer
      def trace(_key, data)
        if (query = data[:query])
          query.context[:no_op_tracer_ran] = true
        end
        yield
      end
    end

    class NoOpInstrumentation
      def before_query(query)
        query.context[:no_op_instrumentation_ran_before_query] = true
      end

      def after_query(query)
        query.context[:no_op_instrumentation_ran_after_query] = true
      end
    end

    class NoOpAnalyzer < GraphQL::Analysis::AST::Analyzer
      def initialize(query_or_multiplex)
        query_or_multiplex.context[:no_op_analyzer_ran_initialize] = true
        super
      end

      def on_leave_field(_node, _parent, visitor)
        visitor.query.context[:no_op_analyzer_ran_on_leave_field] = true
      end

      def result
        query.context[:no_op_analyzer_ran_result] = true
      end
    end

    module PluginWithInstrumentationTracingAndAnalyzer
      def self.use(schema_defn)
        schema_defn.instrument :query, NoOpInstrumentation.new
        schema_defn.tracer NoOpTracer.new
        schema_defn.query_analyzer NoOpAnalyzer
      end
    end

    query_type = Class.new(GraphQL::Schema::Object) do
      graphql_name 'Query'
      field :foobar, Integer, null: false
      def foobar; 1337; end
    end

    describe "when called on class definitions" do
      let(:schema) do
        Class.new(GraphQL::Schema) do
          query query_type
          use PluginWithInstrumentationTracingAndAnalyzer
        end
      end

      let(:query) { GraphQL::Query.new(schema, "query { foobar }") }

      it "attaches plugins correctly, runs all of their callbacks" do
        res = query.result
        assert res.key?("data")

        assert_equal true, query.context[:no_op_instrumentation_ran_before_query]
        assert_equal true, query.context[:no_op_instrumentation_ran_after_query]
        assert_equal true, query.context[:no_op_tracer_ran]
        assert_equal true, query.context[:no_op_analyzer_ran_initialize]
        assert_equal true, query.context[:no_op_analyzer_ran_on_leave_field]
        assert_equal true, query.context[:no_op_analyzer_ran_result]
      end
    end

    describe "when called on schema subclasses" do
      let(:schema) do
        schema = Class.new(GraphQL::Schema) do
          query query_type
        end

        # return a subclass
        Class.new(schema) do
          use PluginWithInstrumentationTracingAndAnalyzer
        end
      end

      let(:query) { GraphQL::Query.new(schema, "query { foobar }") }

      it "attaches plugins correctly, runs all of their callbacks" do
        res = query.result
        assert res.key?("data")

        assert_equal true, query.context[:no_op_instrumentation_ran_before_query]
        assert_equal true, query.context[:no_op_instrumentation_ran_after_query]
        assert_equal true, query.context[:no_op_tracer_ran]
        assert_equal true, query.context[:no_op_analyzer_ran_initialize]
        assert_equal true, query.context[:no_op_analyzer_ran_on_leave_field]
        assert_equal true, query.context[:no_op_analyzer_ran_result]
      end
    end
  end

  describe ".possible_types" do
    it "returns a single item for objects" do
      assert_equal [Dummy::Cheese], Dummy::Schema.possible_types(Dummy::Cheese)
    end

    it "returns empty for abstract types without any possible types" do
      unknown_union = Class.new(GraphQL::Schema::Union) { graphql_name("Unknown") }
      assert_equal [], Dummy::Schema.possible_types(unknown_union)
    end

    it "returns correct types for interfaces based on the context" do
      assert_equal [], Jazz::Schema.possible_types(Jazz::PrivateNameEntity, { private: false })
      assert_equal [Jazz::Ensemble], Jazz::Schema.possible_types(Jazz::PrivateNameEntity, { private: true })
    end

    it "returns correct types for unions based on the context" do
      assert_equal [Jazz::Musician], Jazz::Schema.possible_types(Jazz::PerformingAct, { hide_ensemble: true })
      assert_equal [Jazz::Musician, Jazz::Ensemble], Jazz::Schema.possible_types(Jazz::PerformingAct, { hide_ensemble: false })
    end
  end

  describe 'validate' do
    let(:schema) { Dummy::Schema}

    describe 'validate' do
      it 'validates valid query ' do
        query = "query sample { root }"

        errors = schema.validate(query)

        assert_empty errors
      end

      it 'validates invalid query ' do
        query = "query sample { invalid }"

        errors = schema.validate(query)

        assert_equal(1, errors.size)
      end
    end
  end

  describe "requiring query" do
    class QueryRequiredSchema < GraphQL::Schema
    end
    it "returns an error if no query type is defined" do
      res = QueryRequiredSchema.execute("{ blah }")
      assert_equal ["Schema is not configured for queries"], res["errors"].map { |e| e["message"] }
    end
  end
end
