# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Execution::SelectionsStep do
  class SelectionsStepRunner
    attr_reader :steps

    def initialize(groups)
      @groups = groups
      @steps = []
    end

    def gather_selections(_parent_type, _selections, _step, _query, all_selections, _prototype_result, into:)
      all_selections.replace(@groups)
    end

    def runtime_directives
      GraphQL::EmptyObjects::EMPTY_HASH
    end

    def add_step(step)
      @steps << step
    end
  end

  it "enqueues each field step once across selection groups" do
    first_step = Object.new
    second_step = Object.new
    inline_fragment = GraphQL.parse("{ ... @include(if: true) { __typename } }").definitions.first.selections.first
    runner = SelectionsStepRunner.new([
      { "first" => first_step },
      { "first" => nil },
      { __node: inline_fragment, "second" => second_step },
      { "second" => nil },
    ])
    step = GraphQL::Execution::SelectionsStep.new(
      parent_type: nil,
      field_resolve_step: nil,
      selections: [],
      objects: [],
      results: [{}],
      runner: runner,
      query: Object.new,
      path: [],
      clobber: false,
    )

    step.call

    assert_equal [first_step, second_step], runner.steps
  end
end
