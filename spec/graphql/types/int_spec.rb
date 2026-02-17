# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Types::Int do
  describe "coerce_input" do
    it "accepts ints within the bounds" do
      assert_equal(-(2**31), GraphQL::Types::Int.coerce_isolated_input(-(2**31)))
      assert_equal 1, GraphQL::Types::Int.coerce_isolated_input(1)
      assert_equal (2**31)-1, GraphQL::Types::Int.coerce_isolated_input((2**31)-1)
    end

    it "rejects other types and ints outside the bounds" do
      assert_nil GraphQL::Types::Int.coerce_isolated_input("55")
      assert_nil GraphQL::Types::Int.coerce_isolated_input(true)
      assert_nil GraphQL::Types::Int.coerce_isolated_input(6.1)
      assert_nil GraphQL::Types::Int.coerce_isolated_input(2**31)
      assert_nil GraphQL::Types::Int.coerce_isolated_input(-(2**31 + 1))
    end

    describe "handling boundaries" do
      let(:context) { GraphQL::Query.new(Dummy::Schema, "{ __typename }").context }

      it "accepts result values in bounds" do
        assert_equal 0, GraphQL::Types::Int.coerce_result(0, context)
        assert_equal (2**31) - 1, GraphQL::Types::Int.coerce_result((2**31) - 1, context)
        assert_equal(-(2**31), GraphQL::Types::Int.coerce_result(-(2**31), context))
      end

      it "replaces values, if configured to do so" do
        assert_equal Dummy::Schema::MAGIC_INT_COERCE_VALUE, GraphQL::Types::Int.coerce_result(99**99, context)
      end

      it "raises on values out of bounds" do
        err_ctx = GraphQL::Query.new(Dummy::Schema, "{ __typename }").context
        assert_raises(GraphQL::IntegerEncodingError) { GraphQL::Types::Int.coerce_result(2**31, err_ctx) }
        err = assert_raises(GraphQL::IntegerEncodingError) { GraphQL::Types::Int.coerce_result(-(2**31 + 1), err_ctx) }
        assert_equal "Int cannot represent non 32-bit signed integer value: -2147483649", err.message

        err = assert_raises GraphQL::IntegerEncodingError do
          Dummy::Schema.execute("{ hugeInteger }")
        end
        assert_equal "Int cannot represent non 32-bit signed integer value: 2147483648", err.message
      end

      describe "with Schema.spec_compliant_scalar_coercion_errors" do
        class IntScalarSchema < GraphQL::Schema
          class Query < GraphQL::Schema::Object
            field :int, GraphQL::Types::Int do
              argument :value, GraphQL::Types::Int
            end

            field :bad_int, GraphQL::Types::Int

            def int(value:)
              value
            end

            def bad_int
              2**31 # Out of range
            end
          end

          query(Query)
        end

        class IntSpecCompliantErrors < IntScalarSchema
          spec_compliant_scalar_coercion_errors true
        end

        class IntNonSpecComplaintErrors < IntScalarSchema
          spec_compliant_scalar_coercion_errors false
        end

        it "returns GraphQL execution errors with spec_compliant_scalar_coercion_errors enabled" do
          query = "{ badInt }"
          result = IntSpecCompliantErrors.execute(query)

          assert_equal(
            {
              "errors" => [
                {
                  "message" =>  "Int cannot represent non 32-bit signed integer value: 2147483648",
                  "locations" => [{ "line" => 1, "column" => 3 }],
                  "path" => ["badInt"],
                },
              ],
              "data" => {
                "badInt" => nil,
              }
            },
            result.to_h
          )
        end

        it "raises Ruby exceptions with spec_compliant_scalar_coercion_errors disabled" do
          query = "{ badInt }"

          error = nil
          stdout, stderr = capture_io do
            error = assert_raises(GraphQL::IntegerEncodingError) do
              IntNonSpecComplaintErrors.execute(query)
            end
          end

          expected_warning = "Scalar coercion errors (like this one: `#<GraphQL::IntegerEncodingError message=\"Int cannot represent non 32-bit signed integer value: 2147483648\">`) will return GraphQL execution errors instead of raising Ruby exceptions in a future version.
To opt into this new behavior, set `Schema.spec_compliant_scalar_coercion_errors = true`.
To keep or customize the current behavior, add custom error handling in `IntNonSpecComplaintErrors.type_error`.
"

          assert_equal expected_warning, stderr
          assert_equal "", stdout
          assert_equal("Int cannot represent non 32-bit signed integer value: 2147483648", error.message)
        end
      end
    end
  end
end
