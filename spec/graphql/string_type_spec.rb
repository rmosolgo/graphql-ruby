# frozen_string_literal: true
require "spec_helper"

describe GraphQL::STRING_TYPE do
  let(:string_type) { GraphQL::STRING_TYPE }

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
          assert_equal "String \"#{string}\" was encoded as ASCII-8BIT! GraphQL requires an encoding compatible with UTF-8.", err.message
          assert_equal string, err.string
        end
      end
    end

    describe "when the schema defines a custom handler" do
      let(:schema) {
        GraphQL::Schema.define do
          query(GraphQL::ObjectType.define(name: "Query"))
          type_error ->(err, ctx) {
            ctx.errors << err
            "🌾"
          }
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
