# frozen_string_literal: true
require "spec_helper"

describe GraphQL::STRING_TYPE do
  let(:string_type) { GraphQL::STRING_TYPE }

  it "is a default scalar" do
    assert_equal(true, string_type.default_scalar?)
  end

  describe "coerce_result" do
    let(:binary_str) { "\0\0\0foo\255\255\255".dup.force_encoding("BINARY") }
    it "requires string to be encoded as UTF-8" do
      err = assert_raises(GraphQL::StringEncodingError) {
        string_type.coerce_isolated_result(binary_str)
      }

      assert_equal "String \"#{binary_str}\" was encoded as ASCII-8BIT! GraphQL requires UTF-8 encoding.", err.message
      assert_equal binary_str, err.string
    end

    describe "when the schema defines a custom hander" do
      let(:schema) {
        GraphQL::Schema.define do
          query(GraphQL::ObjectType.define(name: "Query"))
          type_error ->(err, ctx) {
            ctx.errors << err
          }
        end
      }

      let(:context) {
        OpenStruct.new(schema: schema, errors: [])
      }

      it "calls the handler" do
        assert_equal nil, string_type.coerce_result(binary_str, context)
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
      assert_equal nil, string_type.coerce_isolated_input(100)
      assert_equal nil, string_type.coerce_isolated_input(true)
      assert_equal nil, string_type.coerce_isolated_input(0.999)
    end
  end
end
