# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Types::Float do
  let(:enum) { GraphQL::Language::Nodes::Enum.new(name: 'MILK') }

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
  end

  describe "coerce_result" do
    it "coercess ints and floats" do
      err_ctx = GraphQL::Query.new(Dummy::Schema, "{ __typename }").context

      assert_equal 1.0, GraphQL::Types::Float.coerce_result(1, err_ctx)
      assert_equal 1.0, GraphQL::Types::Float.coerce_result("1", err_ctx)
      assert_equal 1.0, GraphQL::Types::Float.coerce_result("1.0", err_ctx)
      assert_equal 6.1, GraphQL::Types::Float.coerce_result(6.1, err_ctx)
    end

    it "rejects other types" do
      err_ctx = GraphQL::Query.new(Dummy::Schema, "{ __typename }").context

      assert_raises(GraphQL::ScalarCoercionError) do
        GraphQL::Types::Float.coerce_result("foo", err_ctx)
      end

      assert_raises(GraphQL::ScalarCoercionError) do
        GraphQL::Types::Float.coerce_result(1.0 / 0, err_ctx)
      end
    end

    describe "with Schema.spec_compliant_scalar_coercion_errors" do
      class FloatScalarSchema < GraphQL::Schema
        class Query < GraphQL::Schema::Object
          field :float, GraphQL::Types::Float do
            argument :value, GraphQL::Types::Float
          end

          field :bad_float, GraphQL::Types::Float

          def float(value:)
            value
          end

          def bad_float
            Float::INFINITY
          end
        end

        query(Query)
      end

      class FloatSpecCompliantErrors < FloatScalarSchema
        spec_compliant_scalar_coercion_errors true
      end

      class FloatNonSpecComplaintErrors < FloatScalarSchema
        spec_compliant_scalar_coercion_errors false
      end

      it "returns GraphQL execution errors with spec_compliant_scalar_coercion_errors enabled" do
        query = "{ badFloat }"
        result = FloatSpecCompliantErrors.execute(query)

        assert_equal(
          {
            "errors" => [
              {
                "message" =>  "Float cannot represent non numeric value: Infinity",
                "locations" => [{ "line" => 1, "column" => 3 }],
                "path" => ["badFloat"],
              },
            ],
            "data" => {
              "badFloat" => nil,
            }
          },
          result.to_h
        )
      end

      it "raises Ruby exceptions with spec_compliant_scalar_coercion_errors disabled" do
        query = "{ badFloat }"

        error = assert_raises(GraphQL::ScalarCoercionError) do
          FloatNonSpecComplaintErrors.execute(query)
        end

        assert_equal("Float cannot represent non numeric value: Infinity", error.message)
      end
    end
  end
end
