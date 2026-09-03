# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Execution::PrepareObjectStep do
  module PrepareObjectStepSpec
    ItemData = Struct.new(:name, keyword_init: true)

    class LazyResult
      def initialize(value)
        @value = value
      end

      def value
        @value
      end
    end

    module Node
      include GraphQL::Schema::Interface
      field :name, String, null: false
    end

    class Item < GraphQL::Schema::Object
      implements Node
      field :name, String, null: false
    end

    class AuthorizedItem < GraphQL::Schema::Object
      field :name, String, null: false

      def self.authorized?(object, context)
        context[:authorization_values] << object.name
        true
      end
    end

    class ScopedItem < GraphQL::Schema::Object
      field :name, String, null: false
      reauthorize_scoped_objects(false)

      def self.scope_items(items, context)
        context[:scope_calls] += 1
        items
      end

      def self.authorized?(object, context)
        context[:authorization_values] << object.name
        true
      end
    end

    class EagerExtension < GraphQL::Schema::FieldExtension
      def after_resolve(context:, value: nil, values: nil, **)
        context[:extension_calls] += 1
        values || value
      end
    end

    class RuntimeDirective < GraphQL::Schema::Directive
      graphql_name "prepareObjectStepRuntime"
      locations FIELD

      def self.resolve(object, arguments, context)
        context[:directive_calls] += 1
        yield
      end

      def self.resolve_field(_ast_nodes, _parent_type, _field_definition, _objects, _arguments, context)
        context[:directive_calls] += 1
        nil
      end
    end

    class PostProcessorDirective < GraphQL::Schema::Directive
      graphql_name "prepareObjectStepPostProcessor"
      locations FIELD

      def self.resolve_field(*)
        Processor.new
      end

      class Processor
        include GraphQL::Execution::PostProcessor

        def after_resolve(field_results)
          field_results
        end
      end
    end

    class FinalizerDirective < GraphQL::Schema::Directive
      graphql_name "prepareObjectStepFinalizer"
      locations FIELD
      repeatable true
      argument :label, String

      def self.resolve_field(_ast_nodes, _parent_type, _field_definition, _objects, arguments, _context)
        Recorder.new(arguments[:label])
      end

      class Recorder
        include GraphQL::Execution::Finalizer

        def initialize(label)
          @label = label
        end

        def finalize_graphql_result(query, _result_data, result_key)
          query.context[:finalizer_calls] << [@label, path.dup, result_key]
        end
      end
    end

    class Query < GraphQL::Schema::Object
      field :items, [Item], null: false, scope: false, resolve_legacy_instance_method: true
      field :authorized_items, [AuthorizedItem], null: false, scope: false, resolve_legacy_instance_method: true
      field :lazy_items, [Item], null: false, scope: false, resolve_legacy_instance_method: true
      field :node, Node, null: false, resolve_legacy_instance_method: true
      field :nested_items, [[Item]], null: false, scope: false, resolve_legacy_instance_method: true
      field :scoped_items, [ScopedItem], null: false, scope: true, resolve_legacy_instance_method: true
      field :extended_items, [Item], null: false, scope: false, extensions: [EagerExtension], resolve_legacy_instance_method: true
      field :items_connection, Item.connection_type, null: false, resolve_legacy_instance_method: true
      field :raw_item, Item, null: false, resolve_legacy_instance_method: true
      field :runtime_error_item, Item, resolve_legacy_instance_method: true
      field :invalid_items, [Item, null: true], null: false, scope: false, resolve_legacy_instance_method: true

      def items
        context[:items]
      end

      def authorized_items
        context[:items]
      end

      def lazy_items
        LazyResult.new(context[:items])
      end

      def node
        context[:items].first
      end

      def nested_items
        [context[:items]]
      end

      def scoped_items
        context[:items]
      end

      def extended_items
        context[:items]
      end

      def items_connection
        context[:items]
      end

      def raw_item
        raw_value({ "name" => "finalized" })
      end

      def runtime_error_item
        GraphQL::ExecutionError.new("object failed")
      end

      def invalid_items
        [ItemData.new(name: nil)]
      end
    end

    module Trace
      def objects(type, objects, context)
        context[:object_batches] << [type.graphql_name, objects.size]
        super
      end

      def begin_authorized(type, object, context)
        if type != Query
          object_name = object.respond_to?(:name) ? object.name : object.class.name
          context[:authorization_trace] << [:begin, type.graphql_name, object_name]
        end
        super
      end

      def end_authorized(type, object, context, authorized_result)
        if type != Query
          object_name = object.respond_to?(:name) ? object.name : object.class.name
          context[:authorization_trace] << [:end, type.graphql_name, object_name, authorized_result]
        end
        super
      end

      def begin_resolve_type(type, object, context)
        context[:resolve_type_trace] << [type.graphql_name, object.name]
        super
      end
    end

    class Schema < GraphQL::Schema
      query(Query)
      directive(RuntimeDirective)
      directive(PostProcessorDirective)
      directive(FinalizerDirective)
      lazy_resolve(LazyResult, :value)
      trace_with(Trace)
      use GraphQL::Execution::Next

      def self.resolve_type(_abstract_type, _object, _context)
        Item
      end
    end

    class SchemaWithoutLazyResolver < GraphQL::Schema
      query(Query)
      trace_with(Trace)
      use GraphQL::Execution::Next
    end
  end

  def test_context
    {
      items: [
        PrepareObjectStepSpec::ItemData.new(name: "One"),
        PrepareObjectStepSpec::ItemData.new(name: "Two"),
      ],
      authorization_values: [],
      authorization_trace: [],
      resolve_type_trace: [],
      object_batches: [],
      scope_calls: 0,
      extension_calls: 0,
      directive_calls: 0,
      finalizer_calls: [],
    }
  end

  def execute_next_with_step_count(query, context: test_context, schema: PrepareObjectStepSpec::Schema)
    prepare_object_step_count = 0
    original_new = GraphQL::Execution::PrepareObjectStep.method(:new)
    counting_new = ->(*args, **kwargs) do
      prepare_object_step_count += 1
      original_new.call(*args, **kwargs)
    end
    result = GraphQL::Execution::PrepareObjectStep.stub(:new, counting_new) do
      schema.execute_next(query, context: context)
    end
    [result, prepare_object_step_count]
  end

  def assert_matches_legacy(query, schema: PrepareObjectStepSpec::Schema)
    legacy_context = test_context
    next_context = test_context
    legacy_result = schema.execute(query, context: legacy_context)
    next_result, step_count = execute_next_with_step_count(query, context: next_context, schema: schema)
    assert_graphql_equal legacy_result.to_h, next_result.to_h
    [next_result, step_count, legacy_context, next_context]
  end

  it "preserves authorization traces when the schema has a lazy resolver" do
    result, step_count, legacy_context, next_context = assert_matches_legacy("{ items { name } }")

    assert_equal 0, step_count
    assert_equal ["One", "Two"], result["data"]["items"].map { |item| item["name"] }
    assert_equal [["Query", 1], ["Item", 2]], next_context[:object_batches]
    assert_equal legacy_context[:authorization_trace], next_context[:authorization_trace]
    assert_equal [
      [:begin, "Item", "One"],
      [:end, "Item", "One", true],
      [:begin, "Item", "Two"],
      [:end, "Item", "Two", true],
    ], next_context[:authorization_trace]
  end

  it "does not add authorization traces when the schema has no lazy resolver" do
    schema = PrepareObjectStepSpec::SchemaWithoutLazyResolver
    result, step_count, _legacy_context, next_context = assert_matches_legacy("{ items { name } }", schema: schema)

    refute schema.resolves_lazies?
    assert_equal 0, step_count
    assert_equal ["One", "Two"], result["data"]["items"].map { |item| item["name"] }
    assert_empty next_context[:authorization_trace]
  end

  it "keeps object preparation for custom authorization" do
    _result, step_count, legacy_context, next_context = assert_matches_legacy("{ authorizedItems { name } }")

    assert_equal 2, step_count
    assert_equal legacy_context[:authorization_values], next_context[:authorization_values]
    assert_equal legacy_context[:authorization_trace], next_context[:authorization_trace]
  end

  it "keeps object preparation for lazy results" do
    _result, step_count = execute_next_with_step_count("{ lazyItems { name } }")

    assert_equal 2, step_count
  end

  it "keeps object preparation for abstract types" do
    _result, step_count, legacy_context, next_context = assert_matches_legacy("{ node { name } }")

    assert_equal 1, step_count
    assert_equal legacy_context[:resolve_type_trace], next_context[:resolve_type_trace]
  end

  it "keeps object preparation for nested lists" do
    _result, step_count = execute_next_with_step_count("{ nestedItems { name } }")

    assert_equal 2, step_count
  end

  it "keeps object preparation for scoped results" do
    _result, step_count, legacy_context, next_context = assert_matches_legacy("{ scopedItems { name } }")

    assert_equal 2, step_count
    assert_equal legacy_context[:scope_calls], next_context[:scope_calls]
    assert_empty next_context[:authorization_values]
  end

  it "uses the fast path after eager extensions and runtime directives" do
    query = <<~GRAPHQL
      {
        extendedItems { name }
        items @prepareObjectStepRuntime { name }
      }
    GRAPHQL
    _result, step_count, legacy_context, next_context = assert_matches_legacy(query)

    assert_equal 0, step_count
    assert_equal legacy_context[:extension_calls], next_context[:extension_calls]
    assert_equal legacy_context[:directive_calls], next_context[:directive_calls]
  end

  it "keeps object preparation for post-processed results" do
    query = "{ items @prepareObjectStepPostProcessor { name } }"
    _result, step_count = assert_matches_legacy(query)

    assert_equal 2, step_count
  end

  it "keeps object preparation for directive finalizers" do
    query = <<~GRAPHQL
      {
        items @prepareObjectStepFinalizer(label: "first") @prepareObjectStepFinalizer(label: "second") { name }
      }
    GRAPHQL
    _result, step_count, _legacy_context, next_context = assert_matches_legacy(query)

    assert_equal 2, step_count
    assert_equal [
      ["first", ["items"], nil],
      ["second", ["items"], nil],
    ], next_context[:finalizer_calls]
  end

  it "preserves connection handling" do
    _result, step_count = assert_matches_legacy("{ itemsConnection(first: 1) { nodes { name } } }")

    assert_operator step_count, :>, 0
  end

  it "preserves finalizers and runtime errors" do
    query = "{ rawItem { name } runtimeErrorItem { name } }"
    result, step_count = execute_next_with_step_count(query)

    assert_equal 0, step_count
    assert_equal({ "rawItem" => { "name" => "finalized" }, "runtimeErrorItem" => nil }, result["data"])
    assert_equal ["object failed"], result["errors"].map { |error| error["message"] }
  end

  it "preserves non-null propagation" do
    result, step_count, _legacy_context, _next_context = assert_matches_legacy("{ invalidItems { name } }")

    assert_equal 0, step_count
    assert_nil result["data"]["invalidItems"].first
    assert_equal [["invalidItems", 0, "name"]], result["errors"].map { |error| error["path"] }
  end
end
