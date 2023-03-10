# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Tracing::LegacyTrace do

  it "calls tracers on a parent schema class" do
    custom_tracer = Module.new do
      def self.trace(key, data)
        if key == "execute_query"
          data[:query].context[:trace_ran] = true
        end
        yield
      end
    end

    query_type = Class.new(GraphQL::Schema::Object) do
      graphql_name("Query")
      field :int, Integer
      def int
        4
      end
    end

    parent_schema = Class.new(GraphQL::Schema) do
      query(query_type)
      tracer(custom_tracer)
    end

    child_schema = Class.new(parent_schema)


    res1 = parent_schema.execute("{ int }")
    assert_equal true, res1.context[:trace_ran]

    res2 = child_schema.execute("{ int }")
    assert_equal true, res2.context[:trace_ran]
  end
end
