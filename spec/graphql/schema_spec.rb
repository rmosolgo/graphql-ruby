# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema do
  describe "inheritance" do
    class DummyFeature1 < GraphQL::Schema::Directive::Feature

    end

    class DummyFeature2 < GraphQL::Schema::Directive::Feature

    end

    let(:base_schema) do
      Class.new(GraphQL::Schema) do
        query GraphQL::Schema::Object
        mutation GraphQL::Schema::Object
        subscription GraphQL::Schema::Object
        max_complexity 1
        max_depth 2
        default_max_page_size 3
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
        instrument :field, GraphQL::Relay::EdgesInstrumentation
        middleware (Proc.new {})
        use GraphQL::Backtrace
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
      assert_equal base_schema.max_complexity, schema.max_complexity
      assert_equal base_schema.max_depth, schema.max_depth
      assert_equal base_schema.default_max_page_size, schema.default_max_page_size
      assert_equal base_schema.error_bubbling, schema.error_bubbling
      assert_equal base_schema.orphan_types, schema.orphan_types
      assert_equal base_schema.context_class, schema.context_class
      assert_equal base_schema.directives, schema.directives
      assert_equal base_schema.tracers, schema.tracers
      assert_equal base_schema.query_analyzers, schema.query_analyzers
      assert_equal base_schema.multiplex_analyzers, schema.multiplex_analyzers
      assert_equal base_schema.rescues, schema.rescues
      assert_equal base_schema.instrumenters, schema.instrumenters
      assert_equal base_schema.middleware.steps.size, schema.middleware.steps.size
      assert_equal base_schema.disable_introspection_entry_points?, schema.disable_introspection_entry_points?
      assert_equal [GraphQL::Backtrace], schema.plugins.map(&:first)
    end

    it "can override configuration from its superclass" do
      schema = Class.new(base_schema)
      query = Class.new(GraphQL::Schema::Object) do
        graphql_name 'Query'
      end
      schema.query(query)
      mutation = Class.new(GraphQL::Schema::Object) do
        graphql_name 'Mutation'
      end
      schema.mutation(mutation)
      subscription = Class.new(GraphQL::Schema::Object) do
        graphql_name 'Subscription'
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
      context_class = Class.new
      schema.context_class(context_class)
      schema.max_complexity(10)
      schema.max_depth(20)
      schema.default_max_page_size(30)
      schema.error_bubbling(true)
      schema.orphan_types(Jazz::InstrumentType)
      schema.directives([DummyFeature2])
      query_analyzer = Object.new
      schema.query_analyzer(query_analyzer)
      multiplex_analyzer = Object.new
      schema.multiplex_analyzer(multiplex_analyzer)
      schema.use(GraphQL::Execution::Interpreter)
      schema.instrument(:field, GraphQL::Relay::ConnectionInstrumentation)
      schema.rescue_from(GraphQL::ExecutionError)
      schema.tracer(GraphQL::Tracing::NewRelicTracing)
      schema.middleware(Proc.new {})

      assert_equal query.graphql_definition, schema.query
      assert_equal mutation.graphql_definition, schema.mutation
      assert_equal subscription.graphql_definition, schema.subscription
      assert_equal introspection, schema.introspection
      assert_equal cursor_encoder, schema.cursor_encoder
      assert_equal query_execution_strategy, schema.query_execution_strategy
      assert_equal mutation_execution_strategy, schema.mutation_execution_strategy
      assert_equal subscription_execution_strategy, schema.subscription_execution_strategy
      assert_equal context_class, schema.context_class
      assert_equal 10, schema.max_complexity
      assert_equal 20, schema.max_depth
      assert_equal 30, schema.default_max_page_size
      assert schema.error_bubbling
      assert_equal [Jazz::Ensemble, Jazz::InstrumentType], schema.orphan_types
      assert_equal schema.directives, GraphQL::Schema.default_directives.merge(DummyFeature1.graphql_name => DummyFeature1, DummyFeature2.graphql_name => DummyFeature2)
      assert_equal base_schema.query_analyzers + [query_analyzer], schema.query_analyzers
      assert_equal base_schema.multiplex_analyzers + [multiplex_analyzer], schema.multiplex_analyzers
      assert_equal [GraphQL::Backtrace, GraphQL::Execution::Interpreter], schema.plugins.map(&:first)
      assert_equal [GraphQL::Relay::EdgesInstrumentation, GraphQL::Relay::ConnectionInstrumentation], schema.instrumenters[:field]
      assert_equal [GraphQL::ExecutionError, StandardError], schema.rescues.keys.sort_by(&:name)
      assert_equal [GraphQL::Tracing::DataDogTracing, GraphQL::Tracing::NewRelicTracing], schema.tracers
      assert_equal 3, schema.middleware.steps.size
    end
  end

  describe "when mixing define and class-based" do
    module MixedSchema
      class Query < GraphQL::Schema::Object
        field :int, Int, null: false
      end

      class Mutation < GraphQL::Schema::Object
        field :int, Int, null: false
      end

      class Subscription < GraphQL::Schema::Object
        field :int, Int, null: false
      end

      Schema = GraphQL::Schema.define do
        query(Query)
        mutation(Mutation)
        subscription(Subscription)
      end
    end

    it "includes root types properly" do
      res = MixedSchema::Schema.as_json
      assert_equal "Query", res["data"]["__schema"]["queryType"]["name"]
      assert_includes res["data"]["__schema"]["types"].map { |t| t["name"] }, "Query"

      assert_equal "Mutation", res["data"]["__schema"]["mutationType"]["name"]
      assert_includes res["data"]["__schema"]["types"].map { |t| t["name"] }, "Mutation"

      assert_equal "Subscription", res["data"]["__schema"]["subscriptionType"]["name"]
      assert_includes res["data"]["__schema"]["types"].map { |t| t["name"] }, "Subscription"
    end
  end
end
