# frozen_string_literal: true
require "spec_helper"

class GraphQL::Schema
  def self.freeze_schema
    own_tracers.freeze
    own_trace_modes.each do |m|
      build_trace_mode(m)
    end
    build_trace_mode(:default)
    own_trace_modes.freeze
    own_multiplex_analyzers.freeze
    own_query_analyzers.freeze
    own_plugins.freeze
    lazy_methods.freeze
    own_references_to.freeze
    types.each do |name, t|
      t.freeze_schema
    end
    visibility.freeze
    freeze
    superclass.respond_to?(:freeze_schema) && superclass.freeze_schema
  end
end

module GraphQL::Schema::Member::BaseDSLMethods
  def freeze_schema
    freeze
  end
end

describe "Use with Ractors" do
  class RactorExampleSchema < GraphQL::Schema
    class Query < GraphQL::Schema::Object
      field :i, Int, fallback_value: 1
    end
    query(Query)
  end
  it "can access some basic GraphQL objects" do
    # Warmup
    GraphQL::Query.new(RactorExampleSchema, "{ __typename}")
    RactorExampleSchema.freeze_schema
    ractor = Ractor.new do
      query = GraphQL::Query.new(RactorExampleSchema, "{ __typename}")
      Ractor.yield(query.class.name)
      # TODO 😅
      # result = query.result.to_h
    end
    assert_equal "GraphQL::Query", ractor.take
  end
end
