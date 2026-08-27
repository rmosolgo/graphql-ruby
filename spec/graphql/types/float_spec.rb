# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Types::Float do
  let(:enum) { GraphQL::Language::Nodes::Enum.new(name: 'MILK') }
  let(:schema) {
    query_type = Class.new(GraphQL::Schema::Object) do
      graphql_name "Query"

      field :echo, Float do
        argument :value, Float
      end
      field :non_finite, Float, resolve_static: true

      def self.non_finite(_context)
        ::Float::NAN
      end

      def non_finite
        self.class.non_finite(nil)
      end
    end

    Class.new(GraphQL::Schema) do
      query(query_type)
    end
  }

  describe "coerce_input" do
    it "accepts ints and floats" do
      assert_equal 1.0, GraphQL::Types::Float.coerce_isolated_input(1)
      assert_equal 6.1, GraphQL::Types::Float.coerce_isolated_input(6.1)
    end

    it "rejects other types" do
      assert_nil GraphQL::Types::Float.coerce_isolated_input("55")
      assert_nil GraphQL::Types::Float.coerce_isolated_input(true)
      assert_nil GraphQL::Types::Float.coerce_isolated_input(enum)
    end

    it "rejects non-finite values" do
      assert_nil GraphQL::Types::Float.coerce_isolated_input(Float::NAN)
      assert_nil GraphQL::Types::Float.coerce_isolated_input(Float::INFINITY)
      assert_nil GraphQL::Types::Float.coerce_isolated_input(-Float::INFINITY)
    end

    it "rejects non-finite literals and variables" do
      literal_result = schema.execute("{ echo(value: 1e400) }")
      assert_includes literal_result["errors"].first["message"], "has an invalid value"

      variable_result = schema.execute(
        "query($value: Float!) { echo(value: $value) }",
        variables: { "value" => Float::NAN },
      )
      assert_includes variable_result["errors"].first["message"], "provided invalid value"
      assert_equal "NaN", variable_result["errors"].first.dig("extensions", "value")
      [literal_result, variable_result].each { |result| JSON.generate(result.to_h) }
    end
  end

  describe "coerce_result" do
    it "accepts finite values" do
      assert_equal 1.0, GraphQL::Types::Float.coerce_isolated_result(1)
      assert_equal 6.1, GraphQL::Types::Float.coerce_isolated_result(6.1)
    end

    it "raises on non-finite values" do
      assert_raises(GraphQL::FloatEncodingError) do
        GraphQL::Types::Float.coerce_isolated_result(Float::INFINITY)
      end
      assert_raises(GraphQL::FloatEncodingError) do
        GraphQL::Types::Float.coerce_isolated_result(-Float::INFINITY)
      end

      err = assert_raises(GraphQL::FloatEncodingError) do
        schema.execute("{ nonFinite }")
      end
      expected_message = exec_next_error_message(
        "Query.nonFinite",
        "Float is not finite: NaN#{if_exec_next("", " @ nonFinite (Query.nonFinite)")}.",
      )
      assert_equal expected_message, err.message
    end
  end
end
