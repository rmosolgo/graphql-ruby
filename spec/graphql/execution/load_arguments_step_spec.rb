# frozen_string_literal: true
require "spec_helper"
require "async" if RUBY_VERSION >= "3.2.0"

class ExecutionLoadArgumentsStepTest < Minitest::Test
  Item = Struct.new(:id)

  class HookError < StandardError
  end

  class LazyValue
    def initialize(&block)
      @block = block
    end

    def value
      @block.call
    end
  end

  class ItemType < GraphQL::Schema::Object
    field :id, ID, null: false

    def self.authorized?(item, context)
      context[:load_state][:authorization_calls] << item.id
      !item.id.start_with?("unauthorized")
    end
  end

  class ItemSource < GraphQL::Dataloader::Source
    def initialize(fetches)
      @fetches = fetches
    end

    def fetch(ids)
      @fetches << ids.dup
      ids.map { |id| Item.new(id) }
    end
  end

  module ItemLoading
    def object_from_id(_type, id, context)
      context[:load_state][:load_calls] << id
      load_mode = if (load_modes = context[:load_modes])
        load_modes.fetch(id, context[:load_mode])
      else
        context[:load_mode]
      end
      case load_mode
      when :lazy
        LazyValue.new { object_for(id) }
      when :lazy_dataloader
        LazyValue.new { context.dataloader.with(ItemSource, context[:load_state][:fetches]).load(id) }
      when :dataloader
        context.dataloader.with(ItemSource, context[:load_state][:fetches]).load(id)
      else
        object_for(id)
      end
    end

    def load_application_object_failed(error)
      context[:load_state][:missing_calls] << error.id
      if context[:replace_missing]
        Item.new("missing-replacement:#{error.id}")
      else
        super
      end
    end

    def unauthorized_object(error)
      context[:load_state][:resolver_unauthorized_calls] << error.object.id
      if context[:replace_unauthorized]
        Item.new("unauthorized-replacement:#{error.object.id}")
      else
        super
      end
    end

    private

    def object_for(id)
      case id
      when /^missing/
        nil
      when /^error/
        raise GraphQL::ExecutionError, "Failed to load #{id}"
      when "unsubscribe"
        error = GraphQL::Schema::Subscription::EarlyUnsubscribe.new
        error.unsubscribed_result = nil
        raise error
      else
        Item.new(id)
      end
    end
  end

  class ListResolver < GraphQL::Schema::Resolver
    include ItemLoading

    type [String], null: false
    argument :ids, [ID], loads: ItemType, as: :items

    def resolve(items:)
      items.map(&:id)
    end
  end

  class ListSubscription < GraphQL::Schema::Subscription
    include ItemLoading

    type [String], null: false
    argument :ids, [ID], loads: ItemType, as: :items

    def subscribe(items:)
      items.map(&:id)
    end

    def update(items:)
      items.map(&:id)
    end
  end

  class ScalarResolver < GraphQL::Schema::Resolver
    type String, null: false
    argument :id, ID, loads: ItemType, as: :item

    def object_from_id(_type, id, context)
      context[:load_state][:load_calls] << id
      Item.new(id)
    end

    def resolve(item:)
      item.id
    end
  end

  class Query < GraphQL::Schema::Object
    field :loaded_items, resolver: ListResolver
    field :loaded_item, resolver: ScalarResolver
  end

  class Mutation < GraphQL::Schema::Object
    field :loaded_items, resolver: ListResolver
  end

  class Subscription < GraphQL::Schema::Object
    field :loaded_items, subscription: ListSubscription
  end

  module LoadTrace
    def object_loaded(argument_definition, object, context)
      context[:load_state][:trace_calls] << [argument_definition.graphql_name, object&.id]
      if context[:raise_object_loaded_trace]
        context[:load_state][:trace_current_fields] << GraphQL::Current.field&.path
        raise HookError, "object_loaded trace failed"
      end
      super
    end
  end

  class Schema < GraphQL::Schema
    query(Query)
    mutation(Mutation)
    subscription(Subscription)
    use GraphQL::Dataloader
    use GraphQL::Execution::Next
    lazy_resolve(LazyValue, :value)
    trace_with(LoadTrace)

    rescue_from(HookError) do |error, _object, _arguments, context, _field|
      context[:load_state][:handled_errors] << [error.message, GraphQL::Current.field&.path]
      raise GraphQL::ExecutionError, "Handled: #{error.message}"
    end

    def self.resolve_type(_type, _object, _context)
      ItemType
    end

    def self.unauthorized_object(error)
      error.context[:load_state][:schema_unauthorized_calls] << error.object.id
      if error.context[:raise_unauthorized_hook]
        raise HookError, "unauthorized hook failed"
      end
      nil
    end
  end

  class NullDataloaderSchema < Schema
    self.dataloader_class = GraphQL::Dataloader::NullDataloader
  end

  if RUBY_VERSION >= "3.2.0"
    class AsyncDataloaderSchema < Schema
      use GraphQL::Dataloader::AsyncDataloader
    end
  end

  class LegacyListLoadStep
    def initialize(field_resolve_step:, arguments:, load_receiver:, argument_values:, argument_definition:)
      @field_resolve_step = field_resolve_step
      @arguments = arguments
      @load_receiver = load_receiver
      @argument_values = argument_values
      @argument_definition = argument_definition
    end

    def call
      pending_steps = @field_resolve_step.pending_steps
      pending_steps.delete(self)
      @argument_values.each_with_index do |argument_value, index|
        step = GraphQL::Execution::LoadArgumentStep.new(
          field_resolve_step: @field_resolve_step,
          arguments: @arguments,
          load_receiver: @load_receiver,
          argument_value: argument_value,
          argument_definition: @argument_definition,
          argument_key: index,
        )
        pending_steps << step
        @field_resolve_step.runner.add_step(step)
      end
      if pending_steps.empty?
        @field_resolve_step.runner.add_step(@field_resolve_step)
      end
      nil
    end
  end

  QUERY = "query($ids: [ID!]!) { loadedItems(ids: $ids) }"
  MUTATION = "mutation($ids: [ID!]!) { loadedItems(ids: $ids) }"
  SUBSCRIPTION = "subscription($ids: [ID!]!) { loadedItems(ids: $ids) }"

  def test_eager_list_loads_match_individual_steps
    [0, 1, 10, 100].each do |size|
      ids = size.times.map(&:to_s)
      result = assert_matches_individual_steps(ids)

      assert_equal ids, result[:result].dig("data", "loadedItems")
      assert_equal ids, result[:load_calls]
      assert_equal ids, result[:trace_calls].map(&:last)
    end
  end

  def test_lazy_list_loads_match_individual_steps
    [1, 10, 100].each do |size|
      ids = size.times.map(&:to_s)
      result = assert_matches_individual_steps(ids, load_mode: :lazy)

      assert_equal ids, result[:result].dig("data", "loadedItems")
      assert_equal ids, result[:load_calls]
      assert_equal ids, result[:trace_calls].map(&:last)
    end
  end

  def test_mixed_eager_and_lazy_values_use_completion_order
    lazy_first = assert_matches_individual_steps(
      ["lazy", "eager"],
      load_modes: { "lazy" => :lazy },
    )
    assert_equal ["eager", "lazy"], lazy_first[:trace_calls].map(&:last)

    lazy_last = assert_matches_individual_steps(
      ["eager", "lazy"],
      load_modes: { "lazy" => :lazy },
    )
    assert_equal ["eager", "lazy"], lazy_last[:trace_calls].map(&:last)
  end

  def test_mixed_eager_and_lazy_errors_use_completion_order
    result = assert_matches_individual_steps(
      ["error-first", "error-last"],
      load_modes: { "error-first" => :lazy },
    )

    assert_equal ["Failed to load error-first"], result[:result]["errors"].map { |error| error["message"] }
  end

  def test_mixed_unauthorized_and_error_values_match_individual_steps
    eager_unauthorized = assert_matches_individual_steps(
      ["unauthorized-value", "error-value"],
      load_modes: { "error-value" => :lazy },
    )
    assert_nil eager_unauthorized[:result].dig("data", "loadedItems")
    assert_equal ["unauthorized-value"], eager_unauthorized[:schema_unauthorized_calls]

    lazy_unauthorized = assert_matches_individual_steps(
      ["error-value", "unauthorized-value"],
      load_modes: { "unauthorized-value" => :lazy },
    )
    assert_nil lazy_unauthorized[:result].dig("data", "loadedItems")
    assert_equal ["unauthorized-value"], lazy_unauthorized[:schema_unauthorized_calls]
  end

  def test_duplicate_ids_keep_hook_and_result_order_and_dataloader_batching
    ids = ["2", "1", "2", "3", "1"]
    eager_result = assert_matches_individual_steps(ids)
    result = execute_list(ids, load_mode: :dataloader)

    assert_equal ids, eager_result[:load_calls]
    assert_equal ids, eager_result[:result].dig("data", "loadedItems")
    assert_equal ids, result[:load_calls]
    assert_equal ids, result[:result].dig("data", "loadedItems")
    assert_equal [["2", "1", "3"]], result[:fetches]
  end

  def test_lazy_values_keep_dataloader_batching
    ids = ["3", "2", "1"]
    result = assert_matches_individual_steps(ids, load_mode: :lazy_dataloader)

    assert_equal ids, result[:result].dig("data", "loadedItems")
    assert_equal [ids], result[:fetches]
  end

  if RUBY_VERSION >= "3.2.0"
    def test_mixed_eager_and_lazy_values_match_individual_steps_with_async_dataloader
      ids = ["lazy", "eager"]
      result = assert_matches_individual_steps(
        ids,
        schema: AsyncDataloaderSchema,
        load_modes: { "lazy" => :lazy },
      )

      assert_equal ids, result[:result].dig("data", "loadedItems")
      assert_equal ids, result[:load_calls]
      assert_equal ["eager", "lazy"], result[:trace_calls].map(&:last)
      assert_empty result[:fetches]
    end

    def test_list_loads_keep_one_batch_with_async_dataloader
      ids = ["3", "2", "1"]
      result = assert_matches_individual_steps(
        ids,
        schema: AsyncDataloaderSchema,
        load_mode: :lazy_dataloader,
      )

      assert_equal ids, result[:result].dig("data", "loadedItems")
      assert_equal ids, result[:load_calls]
      assert_equal ids, result[:trace_calls].map(&:last)
      assert_equal [ids], result[:fetches]
    end
  end

  def test_eager_and_lazy_values_work_with_null_dataloader
    ids = ["1", "2", "3"]

    eager = execute_list(ids, schema: NullDataloaderSchema)
    lazy = execute_list(ids, schema: NullDataloaderSchema, load_mode: :lazy)

    assert_equal ids, eager[:result].dig("data", "loadedItems")
    assert_equal ids, lazy[:result].dig("data", "loadedItems")
  end

  def test_missing_and_execution_errors_select_the_same_error
    missing = assert_matches_individual_steps(["missing-first", "ok", "missing-last"])
    assert_equal ["No object found for `ids: \"missing-last\"`"], missing[:result]["errors"].map { |error| error["message"] }
    assert_equal ["missing-first", "missing-last"], missing[:missing_calls]

    failed = assert_matches_individual_steps(["error-first", "ok", "error-last"])
    assert_equal ["Failed to load error-last"], failed[:result]["errors"].map { |error| error["message"] }

    lazy_failed = assert_matches_individual_steps(["error-first", "ok", "error-last"], load_mode: :lazy)
    assert_equal ["Failed to load error-last"], lazy_failed[:result]["errors"].map { |error| error["message"] }
  end

  def test_missing_and_unauthorized_values_can_be_replaced
    missing = assert_matches_individual_steps(["ok", "missing-value"], replace_missing: true)
    assert_equal ["ok", "missing-replacement:missing-value"], missing[:result].dig("data", "loadedItems")

    unauthorized = assert_matches_individual_steps(["ok", "unauthorized-value"], replace_unauthorized: true)
    assert_equal ["ok", "unauthorized-replacement:unauthorized-value"], unauthorized[:result].dig("data", "loadedItems")
    assert_equal ["unauthorized-value"], unauthorized[:resolver_unauthorized_calls]

    lazy_unauthorized = assert_matches_individual_steps(["ok", "unauthorized-value"], load_mode: :lazy, replace_unauthorized: true)
    assert_equal ["ok", "unauthorized-replacement:unauthorized-value"], lazy_unauthorized[:result].dig("data", "loadedItems")
  end

  def test_unhandled_unauthorized_and_early_unsubscribe_match_individual_steps
    unauthorized = assert_matches_individual_steps(["ok", "unauthorized-value"])
    assert_nil unauthorized[:result].dig("data", "loadedItems")
    assert_equal ["unauthorized-value"], unauthorized[:schema_unauthorized_calls]

    unsubscribed = assert_matches_individual_steps(["ok", "unsubscribe"])
    assert_nil unsubscribed[:result].dig("data", "loadedItems")
  end

  def test_unauthorized_hook_errors_use_query_error_handling
    result = assert_matches_individual_steps(
      ["unauthorized-value"],
      raise_unauthorized_hook: true,
    )

    assert_equal ["Handled: unauthorized hook failed"], result[:result]["errors"].map { |error| error["message"] }
    assert_equal [["unauthorized hook failed", "Query.loadedItems"]], result[:handled_errors]
  end

  def test_object_loaded_trace_errors_keep_current_field_and_use_query_error_handling
    [{}, { load_mode: :lazy }].each do |context_values|
      result = assert_matches_individual_steps(
        ["loaded-value"],
        raise_object_loaded_trace: true,
        **context_values,
      )

      assert_equal ["Handled: object_loaded trace failed"], result[:result]["errors"].map { |error| error["message"] }
      assert_equal ["Query.loadedItems"], result[:trace_current_fields]
      assert_equal [["object_loaded trace failed", "Query.loadedItems"]], result[:handled_errors]
    end
  end

  def test_one_hundred_values_create_one_framework_load_step
    batch_step_count = 0
    scalar_step_count = 0
    batch_new = GraphQL::Execution::LoadArgumentsStep.method(:new)
    scalar_new = GraphQL::Execution::LoadArgumentStep.method(:new)
    batch_factory = ->(**kwargs) {
      batch_step_count += 1
      batch_new.call(**kwargs)
    }
    scalar_factory = ->(**kwargs) {
      scalar_step_count += 1
      scalar_new.call(**kwargs)
    }

    GraphQL::Execution::LoadArgumentsStep.stub(:new, batch_factory) do
      GraphQL::Execution::LoadArgumentStep.stub(:new, scalar_factory) do
        execute_list(100.times.map(&:to_s))
      end
    end

    assert_equal 1, batch_step_count
    assert_equal 0, scalar_step_count
  end

  def test_scalar_loads_keep_the_individual_step
    batch_step_count = 0
    scalar_step_count = 0
    batch_new = GraphQL::Execution::LoadArgumentsStep.method(:new)
    scalar_new = GraphQL::Execution::LoadArgumentStep.method(:new)

    result = GraphQL::Execution::LoadArgumentsStep.stub(:new, ->(**kwargs) { batch_step_count += 1; batch_new.call(**kwargs) }) do
      GraphQL::Execution::LoadArgumentStep.stub(:new, ->(**kwargs) { scalar_step_count += 1; scalar_new.call(**kwargs) }) do
        execute_scalar("5")
      end
    end

    assert_equal "5", result[:result].dig("data", "loadedItem")
    assert_equal 0, batch_step_count
    assert_equal 1, scalar_step_count
  end

  def test_mutation_list_loads_match_individual_steps
    ids = ["lazy", "eager"]
    expected = with_individual_load_steps do
      execute(MUTATION, variables: { "ids" => ids }, schema: Schema, load_modes: { "lazy" => :lazy })
    end
    actual = execute(MUTATION, variables: { "ids" => ids }, schema: Schema, load_modes: { "lazy" => :lazy })

    assert_equal expected, actual
    assert_equal ids, actual[:result].dig("data", "loadedItems")
  end

  def test_subscription_update_early_unsubscribe_matches_individual_steps
    ids = ["ok", "missing-value"]
    expected = with_individual_load_steps { execute_subscription_update(ids) }
    actual = execute_subscription_update(ids)

    assert_equal expected, actual
    assert actual[:unsubscribed]
  end

  private

  def assert_matches_individual_steps(ids, **context_values)
    expected = with_individual_load_steps { execute_list(ids, **context_values) }
    actual = execute_list(ids, **context_values)
    assert_equal expected, actual
    actual
  end

  def with_individual_load_steps
    GraphQL::Execution::LoadArgumentsStep.stub(:new, ->(**kwargs) { LegacyListLoadStep.new(**kwargs) }) do
      yield
    end
  end

  def execute_list(ids, schema: Schema, **context_values)
    execute(QUERY, variables: { "ids" => ids }, schema: schema, **context_values)
  end

  def execute_scalar(id, schema: Schema, **context_values)
    execute("query($id: ID!) { loadedItem(id: $id) }", variables: { "id" => id }, schema: schema, **context_values)
  end

  def execute_subscription_update(ids)
    field = Schema.subscription.fields["loadedItems"]
    topic = GraphQL::Subscriptions::Event.serialize(
      "loadedItems",
      { ids: ids },
      field,
      scope: nil,
    )
    result = execute(
      SUBSCRIPTION,
      variables: { "ids" => ids },
      schema: Schema,
      subscription_topic: topic,
    )
    result[:unsubscribed] = result.delete(:subscriptions)[:unsubscribed]
    result
  end

  def execute(query, variables:, schema:, subscription_topic: nil, **context_values)
    load_state = {
      load_calls: [],
      authorization_calls: [],
      missing_calls: [],
      resolver_unauthorized_calls: [],
      schema_unauthorized_calls: [],
      trace_calls: [],
      trace_current_fields: [],
      handled_errors: [],
      fetches: [],
    }
    context = { load_state: load_state, **context_values }
    result = schema.execute_next(
      query,
      variables: variables,
      context: context,
      subscription_topic: subscription_topic,
    )
    {
      result: result.to_h,
      subscriptions: result.context.namespace(:subscriptions),
      **load_state,
    }
  end
end
