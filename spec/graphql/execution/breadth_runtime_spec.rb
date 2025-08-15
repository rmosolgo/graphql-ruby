# frozen_string_literal: true
require "spec_helper"

describe "GraphQL::Execution::Interpreter for breadth-first execution" do
  # A breadth-first interpreter uses the following runtime interface:
  # - evaluate_selection(result_key, ast_nodes, selections_result)
  # - exit_with_inner_result?
  class SimpleBreadthRuntime < GraphQL::Execution::Interpreter::Runtime
    class BreadthObject < GraphQL::Execution::Interpreter::Runtime::GraphQLResultHash
      attr_accessor :breadth_index
    end

    def initialize(query:)
      query.multiplex = GraphQL::Execution::Multiplex.new(
        schema: query.schema,
        queries: [query],
        context: query.context,
        max_complexity: nil,
      )

      super(query: query, lazies_at_depth: Hash.new { |h, k| h[k] = [] })
      @breadth_results_by_key = {}
    end

    def run
      result = nil
      query.current_trace.execute_multiplex(multiplex: query.multiplex) do
        query.current_trace.execute_query(query: query) do
          result = yield
        end
      end
      result
    ensure
      delete_all_interpreter_context
    end

    def evaluate_breadth_selection(objects, parent_type, node)
      result_key = node.alias || node.name
      @breadth_results_by_key[result_key] = Array.new(objects.size)
      objects.each_with_index do |object, index|
        app_value = parent_type.wrap(object, query.context)
        breadth_object = BreadthObject.new(nil, parent_type, app_value, nil, false, node.selections, false, node, nil, nil)
        breadth_object.ordered_result_keys = []
        breadth_object.breadth_index = index

        state = get_current_runtime_state
        state.current_result_name = nil
        state.current_result = breadth_object
        @dataloader.append_job { evaluate_selection(result_key, node, breadth_object) }
      end

      @dataloader.run
      GraphQL::Execution::Interpreter::Resolve.resolve_each_depth(@lazies_at_depth, @dataloader)

      @breadth_results_by_key[result_key]
    end

    def exit_with_inner_result?(inner_result, result_key, breadth_object)
      @breadth_results_by_key[result_key][breadth_object.breadth_index] = inner_result
      true
    end
  end

  class PassthroughLoader < GraphQL::Batch::Loader
    def perform(objects)
      objects.each { |obj| fulfill(obj, obj) }
    end
  end

  class SimpleHashBatchLoader < GraphQL::Batch::Loader
    def initialize(key)
      super()
      @key = key
    end

    def perform(objects)
      objects.each { |obj| fulfill(obj, obj.fetch(@key)) }
    end
  end

  class UpcaseExtension < GraphQL::Schema::FieldExtension
    def after_resolve(value:, **rest)
      value&.upcase
    end
  end

  class RangeInput < GraphQL::Schema::InputObject
    argument :min, Int
    argument :max, Int

    def prepare
      min..max
    end
  end

  class BaseField < GraphQL::Schema::Field
    def authorized?(obj, args, ctx)
      if !ctx[:field_auth].nil?
        ctx[:field_auth]
      elsif !ctx[:lazy_field_auth].nil?
        PassthroughLoader.load(ctx[:lazy_field_auth])
      elsif !ctx[:field_auth_with_error].nil?
        raise GraphQL::ExecutionError, "Not authorized" unless ctx[:field_auth_with_error]
      else
        true
      end
    end
  end

  class BaseObject < GraphQL::Schema::Object
    field_class BaseField
  end

  class Query < BaseObject
    field :foo, String

    def foo
      object[:foo]
    end

    field :lazy_foo, String

    def lazy_foo
      SimpleHashBatchLoader.for(:foo).load(object)
    end

    field :maybe_lazy_foo, String

    def maybe_lazy_foo
      if object[:foo] == "beep"
        SimpleHashBatchLoader.for(:foo).load(object)
      else
        object[:foo]
      end
    end

    field :nested_lazy_foo, String

    def nested_lazy_foo
      PassthroughLoader
        .load(object)
        .then { |obj| SimpleHashBatchLoader.for(:foo).load(obj) }
        .then { |str| str }
    end

    field :upcase_foo, String, extensions: [UpcaseExtension]

    def upcase_foo
      object[:foo]
    end

    field :lazy_upcase_foo, String, extensions: [UpcaseExtension]

    def lazy_upcase_foo
      SimpleHashBatchLoader.for(:foo).load(object)
    end

    field :go_boom, String

    def go_boom
      raise GraphQL::ExecutionError, "boom"
    end

    field :args, String do |f|
      f.argument :a, String
      f.argument :b, String
    end

    def args(a:, b:)
      "#{a}#{b}"
    end

    field :range, String do |f|
      f.argument :input, RangeInput
    end

    def range(input:)
      "#{input.min}-#{input.max}"
    end

    field :extras, String, extras: [:lookahead]

    def extras(lookahead:)
      lookahead.field.name
    end

    # uses default resolver...
    field :fizz, String
  end

  class BreadthTestSchema < GraphQL::Schema
    use(GraphQL::Batch)
    query Query
  end

  SCHEMA_FROM_DEF = GraphQL::Schema.from_definition(
    %|type Query { a: String }|,
    default_resolve: {
      "Query" => { "a" => ->(obj, _args, _ctx) { obj["a"] } },
    },
  )

  OBJECTS = [{ foo: "fizz" }, { foo: "buzz" }, { foo: "beep" }, { foo: "boom" }].freeze
  EXPECTED_RESULTS = ["fizz", "buzz", "beep", "boom"].freeze

  def test_maps_sync_results
    result = map_breadth_objects(OBJECTS, "{ foo }")
    assert_equal EXPECTED_RESULTS, result
  end

  def test_maps_lazy_results
    result = map_breadth_objects(OBJECTS, "{ lazyFoo }")
    assert_equal EXPECTED_RESULTS, result
  end

  def test_maps_sometimes_lazy_results
    result = map_breadth_objects(OBJECTS, "{ maybeLazyFoo }")
    assert_equal EXPECTED_RESULTS, result
  end

  def test_maps_nested_lazy_results
    result = map_breadth_objects(OBJECTS, "{ nestedLazyFoo }")
    assert_equal EXPECTED_RESULTS, result
  end

  def test_maps_field_extension_results
    result = map_breadth_objects(OBJECTS, "{ upcaseFoo }")
    assert_equal ["FIZZ", "BUZZ", "BEEP", "BOOM"], result
  end

  def test_maps_lazy_field_extension_results
    result = map_breadth_objects(OBJECTS, "{ lazyUpcaseFoo }")
    assert_equal ["FIZZ", "BUZZ", "BEEP", "BOOM"], result
  end

  def test_maps_fields_with_authorization
    context = { field_auth: false }
    result = map_breadth_objects(OBJECTS, "{ foo }", context: context)
    assert_equal [nil, nil, nil, nil], result
  end

  def test_maps_fields_with_lazy_authorization
    context = { lazy_field_auth: false }
    result = map_breadth_objects(OBJECTS, "{ foo }", context: context)
    assert result.all? { |r| r.is_a?(GraphQL::UnauthorizedFieldError) }
  end

  def test_maps_fields_with_authorization_errors
    context = { field_auth_with_error: false }
    result = map_breadth_objects(OBJECTS, "{ foo }", context: context)
    assert result.all? { |r| r.is_a?(GraphQL::ExecutionError) }
  end

  def test_maps_field_errors
    result = map_breadth_objects(OBJECTS, "{ goBoom }")
    assert result.all? { |r| r.is_a?(GraphQL::ExecutionError) }
    assert_equal ["boom", "boom", "boom", "boom"], result.map(&:message)
  end

  def test_maps_basic_arguments
    doc = %|{ args(a:"fizz", b:"buzz") }|
    result = map_breadth_objects([{}], doc)
    assert_equal ["fizzbuzz"], result
  end

  def test_maps_basic_arguments_with_variables
    doc = %|query($b: String) { args(a:"fizz", b: $b) }|
    result = map_breadth_objects([{}], doc, variables: { b: "buzz" })
    assert_equal ["fizzbuzz"], result
  end

  def test_maps_prepared_input_object
    doc = %|{ range(input: { min: 1, max: 2 }) }|
    result = map_breadth_objects([{}], doc)
    assert_equal ["1-2"], result
  end

  def test_maps_prepared_input_object_with_variables
    doc = %|query($b: Int) { range(input: { min: 1, max: $b }) }|
    result = map_breadth_objects([{}], doc, variables: { b: 2 })
    assert_equal ["1-2"], result
  end

  def test_maps_extras_arguments
    result = map_breadth_objects([{}], "{ extras }")
    assert_equal ["extras"], result
  end

  def test_uses_default_resolver_for_hash_keys
    result = map_breadth_objects([{ fizz: "buzz" }], "{ fizz }")
    assert_equal ["buzz"], result
  end

  def test_uses_default_resolver_for_method_calls
    entity = Struct.new(:fizz)
    result = map_breadth_objects([entity.new("buzz")], "{ fizz }")
    assert_equal ["buzz"], result
  end

  def test_maps_schemas_from_definition
    objects = [{ "a" => "1" }, { "a" => "2" }]
    result = map_breadth_objects(objects, "{ a }", schema: SCHEMA_FROM_DEF)
    assert_equal ["1", "2"], result
  end

  def test_maps_results_with_multiple_nodes
    result = map_breadth_objects(OBJECTS, "{ foo foo }")
    assert_equal EXPECTED_RESULTS, result
  end

  private

  def map_breadth_objects(objects, doc, schema: BreadthTestSchema, variables: {}, context: {})
    query = GraphQL::Query.new(
      schema,
      document: GraphQL.parse(doc),
      variables: variables,
      context: context,
    )

    node = query.document.definitions.first.selections.first
    runtime = SimpleBreadthRuntime.new(query: query)
    runtime.run { runtime.evaluate_breadth_selection(objects, schema.query, node) }
  end
end
