# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::BuildFromDefinition::DefineInstrumentation do
  let(:instrumentation) { GraphQL::Schema::BuildFromDefinition::DefineInstrumentation }

  describe "PATTERN" do
    let(:pattern) { instrumentation::PATTERN }
    it "matches macros" do
      assert_match pattern, "@thing"
      assert_match pattern, "@thing 1, 2"
      assert_match pattern, "@thing 1, b: 2"
    end
  end

  describe ".instrument" do
    it "applies instrumentation based on the description, removing the macro" do
      field = GraphQL::Field.define do
        name "f"
        description "Calls prop\n@name \"f2\"\n@property :prop\n"
      end

      field_2 = instrumentation.instrument(field)

      assert_equal :prop, field_2.property
      assert_equal "f2", field_2.name
      assert_equal "Calls prop", field_2.description
    end

    it "applies to types" do
      type = GraphQL::ObjectType.define do
        name "Thing"
        description "@metadata :a, 1\n@metadata :x, Float::INFINITY"
      end

      type_2 = instrumentation.instrument(type)
      assert_equal "", type_2.description
      assert_equal 1, type_2.metadata[:a]
      assert_equal Float::INFINITY, type_2.metadata[:x]
    end

    it "applies to schemas" do
      schema = GraphQL::Schema.from_definition <<-GRAPHQL
      type Query { i: Int! }
      # @max_complexity 100
      schema {
        query: Query
      }
      GRAPHQL

      schema_2 = instrumentation.instrument(schema)
      assert_equal 100, schema_2.max_complexity
    end

    it "gives a decent backtrace when the syntax isn't valid ruby"
  end
end
