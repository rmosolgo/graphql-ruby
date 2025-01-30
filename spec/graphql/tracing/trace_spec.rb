# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Tracing::Trace do
  it "has all its methods in the development cop" do
    require_relative "../../../cop/development/trace_calls_super_cop"
    superable_methods = GraphQL::Tracing::Trace.instance_methods(false)
    assert_equal superable_methods.sort, Cop::Development::TraceCallsSuperCop::TRACE_HOOKS
  end
end
