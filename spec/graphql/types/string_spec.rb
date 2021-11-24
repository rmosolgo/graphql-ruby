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
          assert_equal "String \"\\x00\\x00\\x00foo\\xAD\\xAD\\xAD\" was encoded as ASCII-8BIT. GraphQL requires an encoding compatible with UTF-8.", err.message
          assert_equal string, err.string
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

        it "includes location in the error message" do
          err = assert_raises GraphQL::StringEncodingError do
            schema.execute("{ badString }")
          end
          expected_err = "String \"\\x00\\x00\\x00foo\\xAD\\xAD\\xAD\" was encoded as ASCII-8BIT @ badString (Query.badString). GraphQL requires an encoding compatible with UTF-8."
          assert_equal expected_err, err.message
        end
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
end
