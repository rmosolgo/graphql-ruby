# frozen_string_literal: true
require "spec_helper"

describe "Built-in scalar result coercion" do
  class ScalarResultQuery < GraphQL::Schema::Object
    field :int, Integer, hash_key: :int
    field :float, Float, hash_key: :float
    field :boolean, Boolean, hash_key: :boolean
    field :required_int, Integer, null: false, hash_key: :required_int
    field :ints, [Integer, null: true], hash_key: :ints
    field :required_ints, [Integer], hash_key: :required_ints
    field :good, String, hash_key: :good
    field :child, self, hash_key: :child
    field :children, [self], hash_key: :children
  end

  class ScalarResultSchema < GraphQL::Schema
    query(ScalarResultQuery)
  end

  {
    int: [[0, 0], [1.0, 1], ["123", 123], ["010", 10], [Rational(6, 2), 3]],
    float: [[1, 1.0], [6.1, 6.1], ["123", 123.0], ["1.5", 1.5]],
    boolean: [[true, true], [false, false], [0, false], [0.0, false], [1, true], [-1.5, true]],
  }.each do |field, examples|
    examples.each do |value, expected|
      it "coerces #{field} result #{value.inspect} without losing information" do
        result = ScalarResultSchema.execute("{ #{field} }", root_value: { field => value })
        assert_equal({ "data" => { field.to_s => expected } }, result.to_h)
      end
    end
  end

  {
    int: [1.5, "abc", "12abc", true, Float::NAN, Float::INFINITY, -Float::INFINITY, Rational(3, 2), 2**31],
    float: ["abc", "12abc", true, Float::NAN, Float::INFINITY, -Float::INFINITY],
    boolean: ["true", "false", Object.new, Float::NAN, Float::INFINITY, -Float::INFINITY],
  }.each do |field, values|
    values.each do |value|
      it "returns a field error for invalid #{field} result #{value.inspect}" do
        result = ScalarResultSchema.execute("{ bad: #{field} good }", root_value: { field => value, good: "ok" })
        assert_equal({ "bad" => nil, "good" => "ok" }, result["data"])
        assert_equal 1, result["errors"].size
        assert_equal ["bad"], result["errors"].first["path"]
        assert_equal [{ "line" => 1, "column" => 3 }], result["errors"].first["locations"]
        JSON.generate(result.to_h)
      end
    end
  end

  it "propagates a failed non-null scalar to the nullable parent" do
    result = ScalarResultSchema.execute("{ requiredInt good }", root_value: { required_int: 1.5, good: "ok" })
    assert_nil result["data"]
    assert_equal 1, result["errors"].size
    assert_equal ["requiredInt"], result["errors"].first["path"]
  end

  it "keeps valid list items when a nullable item cannot be coerced" do
    result = ScalarResultSchema.execute("{ ints good }", root_value: { ints: [1, 1.5, 2], good: "ok" })
    assert_equal({ "ints" => [1, nil, 2], "good" => "ok" }, result["data"])
    assert_equal 1, result["errors"].size
    assert_equal ["ints", 1], result["errors"].first["path"]
  end

  it "propagates a failed non-null item to the nullable list" do
    result = ScalarResultSchema.execute("{ requiredInts good }", root_value: { required_ints: [1, 1.5, 2], good: "ok" })
    assert_equal({ "requiredInts" => nil, "good" => "ok" }, result["data"])
    assert_equal 1, result["errors"].size
    assert_equal ["requiredInts", 1], result["errors"].first["path"]
  end

  it "keeps other objects when one result in a batch cannot be coerced" do
    result = ScalarResultSchema.execute("{ children { int } good }", root_value: { children: [{ int: 1 }, { int: 1.5 }, { int: 2 }], good: "ok" })
    assert_equal({ "children" => [{ "int" => 1 }, { "int" => nil }, { "int" => 2 }], "good" => "ok" }, result["data"])
    assert_equal 1, result["errors"].size
    assert_equal ["children", 1, "int"], result["errors"].first["path"]
  end

  it "propagates a non-null coercion error only to the nullable parent" do
    result = ScalarResultSchema.execute("{ child { requiredInt } good }", root_value: { child: { required_int: 1.5 }, good: "ok" })
    assert_equal({ "child" => nil, "good" => "ok" }, result["data"])
    assert_equal 1, result["errors"].size
    assert_equal ["child", "requiredInt"], result["errors"].first["path"]
  end

  it "keeps nullable null results" do
    assert_equal({ "data" => { "int" => nil, "float" => nil, "boolean" => nil } }, ScalarResultSchema.execute("{ int float boolean }", root_value: {}).to_h)
  end

  it "allows the type_error hook to replace a non-finite float" do
    schema = Class.new(ScalarResultSchema) do
      def self.type_error(error, context)
        if error.is_a?(GraphQL::FloatEncodingError)
          context[:coercion_error] = error
          0.5
        else
          super
        end
      end
    end
    context = {}
    result = schema.execute("{ float }", root_value: { float: Float::NAN }, context: context)
    assert_equal({ "data" => { "float" => 0.5 } }, result.to_h)
    assert_instance_of GraphQL::FloatEncodingError, context[:coercion_error]
  end
end
