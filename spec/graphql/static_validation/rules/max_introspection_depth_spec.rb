# frozen_string_literal: true
require "spec_helper"

describe "Maximum introspection depth" do
  class IntrospectionDepthSchema < GraphQL::Schema
    class Node < GraphQL::Schema::Object
      graphql_name "N"
      6.times { |i| field "child#{i}", self }
      field :fields, self
    end

    query(Node)
    use GraphQL::Execution::Next
  end

  def nested_fields(depth)
    "fields { type { " * depth + "name" + " } }" * depth
  end

  def validation_errors(query_string)
    IntrospectionDepthSchema.validate(query_string).map(&:to_h)
  end

  ["__type(name: \"N\")", "__schema { types"].each do |entry_point|
    ["fields", "interfaces", "possibleTypes", "inputFields"].each do |field_name|
      it "rejects three nested #{field_name} lists from #{entry_point}" do
        selection = "name"
        3.times do
          selection = "type { #{selection} }" if field_name == "fields" || field_name == "inputFields"
          selection = "#{field_name} { #{selection} }"
        end
        query = "{ #{entry_point} { #{selection} } }"
        query << " }" if entry_point.start_with?("__schema")
        errors = validation_errors(query)
        assert_equal 1, errors.length
        assert_equal "Maximum introspection depth exceeded", errors[0]["message"]
        assert_equal "maxIntrospectionDepthExceeded", errors[0]["extensions"]["code"]
      end
    end
  end

  it "reports the aliased introspection entry point" do
    query = "query Test { schema: __type(name: \"N\") { #{nested_fields(3)} } }"
    assert_equal [{
      "message" => "Maximum introspection depth exceeded",
      "locations" => [{"line" => 1, "column" => 14}],
      "path" => ["query Test", "schema"],
      "extensions" => {"code" => "maxIntrospectionDepthExceeded"},
    }], validation_errors(query)
  end

  it "counts different introspection lists along the same path" do
    query = '{ __type(name: "N") { interfaces { possibleTypes { fields { name } } } } }'
    assert_equal ["Maximum introspection depth exceeded"], validation_errors(query).map { |e| e["message"] }
  end

  it "allows two nested lists, sibling lists, and separate entry points" do
    query = <<-GRAPHQL
    {
      first: __type(name: "N") {
        #{nested_fields(2)}
        a: fields { name }
        b: fields { name }
        c: fields { name }
      }
      second: __type(name: "N") { #{nested_fields(2)} }
    }
    GRAPHQL
    assert_empty validation_errors(query)
  end

  it "follows named and inline fragments through ofType" do
    query = <<-GRAPHQL
    { ...Root }
    fragment Root on N { __type(name: "N") { ...First } }
    fragment First on __Type { fields { type { ... on __Type { ofType { ...Second } } } } }
    fragment Second on __Type { fields { type { ... { ...Third } } } }
    fragment Third on __Type { fields { name } }
    GRAPHQL
    assert_equal ["Maximum introspection depth exceeded"], validation_errors(query).map { |e| e["message"] }
  end

  it "rechecks shared fragments when reached at a greater depth" do
    query = <<-GRAPHQL
    { __type(name: "N") { ...Fields fields { type { ...Fields } } } }
    fragment Fields on __Type { #{nested_fields(2)} }
    GRAPHQL
    assert_equal ["Maximum introspection depth exceeded"], validation_errors(query).map { |e| e["message"] }
  end

  it "checks each introspection entry point independently" do
    query = <<-GRAPHQL
    {
      first: __type(name: "N") { ...Fields }
      second: __type(name: "N") { ...Fields }
    }
    fragment Fields on __Type { #{nested_fields(3)} }
    GRAPHQL
    assert_equal [["query", "first"], ["query", "second"]], validation_errors(query).map { |e| e["path"] }
  end

  it "does not repeatedly traverse a shared fragment at the same depth" do
    fragments = 10.times.map { |i| "fragment F#{i} on __Type { ...F#{i + 1} ...F#{i + 1} }" }.join(" ")
    query = '{ __type(name: "N") { ...F0 } } ' + fragments + ' fragment F10 on __Type { fields { name } }'
    calls = 0
    trace = TracePoint.new(:call) do |event|
      calls += 1 if event.method_id == :introspection_depth_exceeded?
    end
    errors = nil
    trace.enable { errors = validation_errors(query) }
    assert_empty errors
    assert_operator calls, :<=, 50
  end

  it "leaves missing fragments and cycles to their existing validation rules" do
    missing = '{ __type(name: "N") { ...Missing } }'
    cycle = '{ __type(name: "N") { ...Cycle } } fragment Cycle on __Type { ...Cycle }'
    assert_equal ["useAndDefineFragment"], validation_errors(missing).map { |e| e["extensions"]["code"] }
    assert_equal ["infiniteLoop"], validation_errors(cycle).map { |e| e["extensions"]["code"] }
  end

  it "does not count ordinary fields with the same names" do
    assert_empty validation_errors("{ fields { fields { fields { __typename } } } }")
  end

  it "allows deeply wrapped type references" do
    query = '{ __type(name: "N") { fields { type { ' + "ofType { " * 12 + "name" + " }" * 12 + " } } } }"
    assert_empty validation_errors(query)
  end

  it "respects the validation error limit" do
    schema = Class.new(IntrospectionDepthSchema) { validate_max_errors 1 }
    query = "{ a: __type(name: \"N\") { #{nested_fields(3)} } b: __type(name: \"N\") { #{nested_fields(3)} } }"
    assert_equal 1, schema.validate(query).length
  end

  [:execute, :execute_next].each do |engine|
    it "rejects excessive introspection before #{engine} with no query depth limit" do
      assert_nil IntrospectionDepthSchema.max_depth
      result = IntrospectionDepthSchema.public_send(engine, "{ __type(name: \"N\") { #{nested_fields(3)} } }")
      refute result.key?("data")
      assert_equal ["Maximum introspection depth exceeded"], result["errors"].map { |e| e["message"] }
    end

    it "rejects excessive introspection before #{engine} when excluded from depth analysis" do
      schema = Class.new(IntrospectionDepthSchema) { max_depth 1, count_introspection_fields: false }
      result = schema.public_send(engine, "{ __type(name: \"N\") { #{nested_fields(3)} } }")
      refute result.key?("data")
      assert_equal ["Maximum introspection depth exceeded"], result["errors"].map { |e| e["message"] }
    end

    it "allows standard introspection queries with #{engine}" do
      [GraphQL::Introspection::INTROSPECTION_QUERY, GraphQL::Introspection.query(
        include_deprecated_args: true,
        include_schema_description: true,
        include_is_repeatable: true,
        include_specified_by_url: true,
        include_is_one_of: true,
      )].each do |query|
        result = IntrospectionDepthSchema.public_send(engine, query)
        refute result.key?("errors")
        assert_equal "N", result["data"]["__schema"]["queryType"]["name"]
      end
    end
  end
end
