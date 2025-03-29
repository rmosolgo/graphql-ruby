# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Types::String do
  let(:string_type) { GraphQL::Types::String }

  it "is a default scalar" do
    assert_equal(true, string_type.default_scalar?)
  end

  describe "coerce_result" do
    let(:utf_8_str) { "foobar" }
    let(:ascii_str) { "foobar".encode(Encoding::ASCII_8BIT) }
    let(:binary_str) { "\0\0\0foo\255\255\255".dup.force_encoding("BINARY") }

    describe "encoding" do
      subject { string_type.coerce_isolated_result(string) }

      describe "when result is encoded as UTF-8" do
        let(:string) { utf_8_str }

        it "returns the string" do
          assert_equal subject, string
        end
      end

      describe "when the result is not UTF-8 but can be transcoded" do
        let(:string) { ascii_str }

        it "returns the string transcoded to UTF-8" do
          assert_equal subject, string.encode(Encoding::UTF_8)
        end
      end

      describe "when the result is not UTF-8 and cannot be transcoded" do
        let(:string) { binary_str }

        it "raises GraphQL::StringEncodingError" do
          err = assert_raises(GraphQL::StringEncodingError) { subject }
          assert_equal "String cannot represent value: \"\\x00\\x00\\x00foo\\xAD\\xAD\\xAD\"", err.message
        end
      end

      describe "In queries" do
        let(:schema) {
          query_type = Class.new(GraphQL::Schema::Object) do
            graphql_name "Query"

            field :bad_string, String
            def bad_string
              "\0\0\0foo\255\255\255".dup.force_encoding("BINARY")
            end
          end

          Class.new(GraphQL::Schema) do
            query(query_type)
          end
        }
      end
    end

    describe "when the schema defines a custom handler" do
      let(:schema) {
        Class.new(GraphQL::Schema) do
          def self.type_error(err, ctx)
            ctx.errors << err
            "🌾"
          end
        end
      }

      let(:context) {
        OpenStruct.new(schema: schema, errors: [])
      }

      it "calls the handler" do
        assert_equal "🌾", string_type.coerce_result(binary_str, context)
        err = context.errors.last
        assert_instance_of GraphQL::StringEncodingError, err
      end
    end
  end

  describe "coerce_input" do
    it "accepts strings" do
      assert_equal "str", string_type.coerce_isolated_input("str")
    end

    it "doesn't accept other types" do
      assert_nil string_type.coerce_isolated_input(100)
      assert_nil string_type.coerce_isolated_input(true)
      assert_nil string_type.coerce_isolated_input(0.999)
    end
  end


  describe "unicode escapes" do
    class UnicodeEscapeSchema < GraphQL::Schema
      class QueryType < GraphQL::Schema::Object
        field :get_string, String do
          argument :string, String
        end

        def get_string(string:)
          string
        end
      end

      query(QueryType)
    end

    it "parses escapes properly in single-quoted strings" do
      query_str = File.read("./spec/fixtures/unicode_escapes/query1.graphql")
      res = UnicodeEscapeSchema.execute(query_str)
      assert_equal "d", res["data"]["example1"]
      assert_equal "\\u0064", res["data"]["example2"]
      assert_equal "\\u006", res["data"]["example4"]

      error_query_str = query_str.gsub("  # ", "  ")
      res2 = UnicodeEscapeSchema.execute(error_query_str)
      expected_err = if USING_C_PARSER
        "syntax error, unexpected invalid token (\"\\\"\") at [4, 31]"
      else
        "Expected string or block string, but it was malformed"
      end
      assert_equal [expected_err], res2["errors"].map { |err| err["message"] }
    end

    it "parses escapes properly in triple-quoted strings" do
      query_str = File.read("./spec/fixtures/unicode_escapes/query2.graphql")
      res = UnicodeEscapeSchema.execute(query_str)
      # No replacing in block strings:
      assert_equal "\\a", res["data"]["example1"]
      assert_equal "\\u006", res["data"]["example2"]
      assert_equal "\\n", res["data"]["example3"]
      assert_equal "\\u0064", res["data"]["example4"]
    end
  end

  describe "with Schema.spec_compliant_scalar_coercion_errors" do
    class StringErrorsSchema < GraphQL::Schema
      class Query < GraphQL::Schema::Object
        field :string, GraphQL::Types::String do
          argument :value, GraphQL::Types::String
        end

        field :bad_string, GraphQL::Types::String

        def string(value:)
          value
        end

        def bad_string
          "\0\0\0foo\255\255\255".dup.force_encoding("BINARY")
        end
      end

      query(Query)
    end

    class StringSpecCompliantErrors < StringErrorsSchema
      spec_compliant_scalar_coercion_errors true
    end

    class StringNonSpecComplaintErrors < StringErrorsSchema
      spec_compliant_scalar_coercion_errors false
    end

    it "returns GraphQL execution errors with spec_compliant_scalar_coercion_errors enabled" do
      query = "{ badString }"
      result = StringSpecCompliantErrors.execute(query)

      assert_equal(
        {
          "errors" => [
            {
              "message" =>  "String cannot represent value: \"\\x00\\x00\\x00foo\\xAD\\xAD\\xAD\"",
              "locations" => [{ "line" => 1, "column" => 3 }],
              "path" => ["badString"],
            },
          ],
          "data" => {
            "badString" => nil,
          }
        },
        result.to_h
      )
    end

    it "raises Ruby exceptions with spec_compliant_scalar_coercion_errors disabled" do
      query = "{ badString }"

      error = assert_raises(GraphQL::StringEncodingError) do
        StringNonSpecComplaintErrors.execute(query)
      end

      assert_equal("String cannot represent value: \"\\x00\\x00\\x00foo\\xAD\\xAD\\xAD\"", error.message)
    end
  end
end
