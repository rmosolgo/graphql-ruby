# frozen_string_literal: true
require "spec_helper"

describe "Trace modes for schemas" do
  module TraceModesTest
    class ParentSchema < GraphQL::Schema
      module GlobalTrace
        def execute_query(query:)
          query.context[:global_trace] = true
          super
        end
      end

      module SpecialTrace
        def execute_query(query:)
          query.context[:special_trace] = true
          super
        end
      end

      module OptionsTrace
        def initialize(configured_option:, **_rest)
          @configured_option = configured_option
          super
        end

        def execute_query(query:)
          query.context[:configured_option] = @configured_option
          super
        end
      end

      class Query < GraphQL::Schema::Object
        field :greeting, String, fallback_value: "Howdy!"
      end

      query(Query)

      trace_with GlobalTrace
      trace_with SpecialTrace, mode: :special
      trace_with OptionsTrace, mode: :options, configured_option: :was_configured
    end

    class ChildSchema < ParentSchema
      module ChildSpecialTrace
        def execute_query(query:)
          query.context[:child_special_trace] = true
          super
        end
      end

      trace_with(ChildSpecialTrace, mode: [:special, :extra_special])
    end

    class GrandchildSchema < ChildSchema
      module GrandchildDefaultTrace
        def execute_query(query:)
          query.context[:grandchild_default] = true
          super
        end
      end

      trace_with GrandchildDefaultTrace
    end
  end

  it "traces are inherited from default modes and from superclass settings for special modes" do
    res = TraceModesTest::ParentSchema.execute("{ greeting }")
    assert res.context[:global_trace]
    refute res.context[:grandchild_default]

    res = TraceModesTest::ChildSchema.execute("{ greeting }")
    assert res.context[:global_trace]
    refute res.context[:grandchild_default]

    res = TraceModesTest::GrandchildSchema.execute("{ greeting }")
    assert res.context[:global_trace]
    assert res.context[:grandchild_default]


    res = TraceModesTest::ParentSchema.execute("{ greeting }", context: { trace_mode: :special })
    assert res.context[:global_trace]
    assert res.context[:special_trace]
    refute res.context[:child_special_trace]
    refute res.context[:grandchild_default]

    res = TraceModesTest::ChildSchema.execute("{ greeting }", context: { trace_mode: :special })
    assert res.context[:global_trace]
    assert res.context[:special_trace]
    assert res.context[:child_special_trace]
    refute res.context[:grandchild_default]

    # This doesn't inherit `:special` configs from ParentSchema:
    res = TraceModesTest::ChildSchema.execute("{ greeting }", context: { trace_mode: :extra_special })
    assert res.context[:global_trace]
    refute res.context[:special_trace]
    assert res.context[:child_special_trace]
    refute res.context[:grandchild_default]

    res = TraceModesTest::GrandchildSchema.execute("{ greeting }", context: { trace_mode: :special })
    assert res.context[:global_trace]
    assert res.context[:special_trace]
    assert res.context[:child_special_trace]
    assert res.context[:grandchild_default]
  end

  it "Only requires and passes arguments for the modes that require them" do
    res = TraceModesTest::ParentSchema.execute("{ greeting }", context: { trace_mode: :options })
    assert_equal :was_configured, res.context[:configured_option]
  end
end
