# frozen_string_literal: true
require "spec_helper"

class ExecutionInputValuesTest < Minitest::Test
  class TestSchema < GraphQL::Schema
    class TestStatus < GraphQL::Schema::Enum
      value :ACTIVE
      value :INACTIVE
    end

    class TestInput < GraphQL::Schema::InputObject
      argument :string, String, required: false
      argument :float, Float, required: false
      argument :int, Int, required: false
      argument :enum, TestStatus, required: false
    end

    class Mutation < GraphQL::Schema::Object
      field :test_input, Boolean do
        argument :input, TestInput, required: false
      end

      field :test_list_input, Boolean do
        argument :input, [TestInput, null: true], required: false
      end
    end

    mutation(Mutation)
    query(Mutation) # Just to have something
  end

  class DummyRunner
    def add_step(s); end
    def schema; TestSchema; end
  end

  def get_input_values(query_string: nil, variables_string: nil, variables: nil)
    query_string ||= "query#{variables_string ? "(#{variables_string})" : ""} { __typename }"
    query = GraphQL::Query.new(TestSchema, query_string, validate: false, variables: variables)
    GraphQL::Execution::InputValues.new(query, DummyRunner.new)
  end

  def get_argument_nodes(arg_string)
    GraphQL.parse("query @something(#{arg_string}) { t }").definitions.first.directives.first.arguments
  end

  def test_coerce_variable_values_empty_inputs_returns_empty
    input = get_input_values
    assert_equal({}, input.variable_values)
  end

  def test_it_works_with_simple_scalars
    input = get_input_values(variables_string: "$name: String, $count: Int, $average: Float, $isOk: Boolean", variables: { "name" => "hello", "count" => 1, "average" => 3.4, "isOk" => false })
    assert_equal({ "name" => "hello", "count" => 1, "average" => 3.4, "isOk" => false  }, input.variable_values)

    with_defaults_str = "$name: String = \"def\", $count: Int = 10, $average: Float = 300.4, $isOk: Boolean = true"

    input = get_input_values(variables_string: with_defaults_str, variables: { "name" => "hello", "count" => 1, "average" => 3.4, "isOk" => false })
    assert_equal({ "name" => "hello", "count" => 1, "average" => 3.4, "isOk" => false  }, input.variable_values)

    input = get_input_values(variables_string: with_defaults_str)
    assert_equal({ "name" => "def", "count" => 10, "average" => 300.4, "isOk" => true  }, input.variable_values)
  end

  def test_it_produces_argument_values_for_simple_scalars
    vs = "$if: Boolean = false"
    input = get_input_values(variables_string: vs)
    assert_equal_input( { if: false }, input.argument_values(GraphQL::Schema::Directive::Skip, get_argument_nodes("if: $if"), nil))
    assert_equal_input( { if: true }, input.argument_values(GraphQL::Schema::Directive::Skip, get_argument_nodes("if: true"), nil))
  end

  def test_it_produces_argument_values_for_input_objects
    input = get_input_values
    assert_equal_input( {input: { string: "a", enum: "ACTIVE" } }, input.argument_values(TestSchema.find("Mutation.testInput"), get_argument_nodes("input: { string: \"a\", enum: ACTIVE }"), nil))
  end

  def assert_equal_input(expected_ruby_hash, graphql_input, path = [])
    if path.empty? && graphql_input.is_a?(Array) && graphql_input.last.nil? && expected_ruby_hash.is_a?(Hash)
      graphql_input = graphql_input.first # ignore the `nil` errors in the multiple return
    end
    case expected_ruby_hash
    when Array
      assert_instance_of Array, graphql_input, "Matches at `#{path.join(".")}`"
      expected_ruby_hash.each_with_index do |next_expected, idx|
        assert_equal_input(next_expected, graphql_input[idx], path + [idx])
      end
    when Hash
      if path.empty?
        assert_instance_of Hash, graphql_input, "Matches at `#{path.join(".")}`"
      else
        assert_kind_of GraphQL::Schema::InputObject, graphql_input, "Matches at `#{path.join(".")}`"
        graphql_input = graphql_input.to_h
      end
      expected_ruby_hash.each do |k, v|
        assert_equal_input(v, graphql_input[k], path + [k])
      end
    else
      assert_equal expected_ruby_hash, graphql_input, "Matches at `#{path.join(".")}`"
    end
  end

  def test_it_works_with_arrays_of_input_objects
    input = get_input_values(variables_string: "$string: String = \"abc\", $string2: String, $input: TestInput!", variables: { string2: "xyz", input: { string: "nested" }})
    assert_equal_input({input: [{}]}, input.argument_values(TestSchema.find("Mutation.testListInput"), get_argument_nodes("input: { string: $s }"), nil))
    assert_equal_input({input: [{ string: "Str" }]}, input.argument_values(TestSchema.find("Mutation.testListInput"), get_argument_nodes("input: { string: \"Str\" }"), nil))
    assert_equal_input({input: [{ string: "abc" }]}, input.argument_values(TestSchema.find("Mutation.testListInput"), get_argument_nodes("input: { string: $string }"), nil))
    assert_equal_input({input: [{ string: "xyz" }]}, input.argument_values(TestSchema.find("Mutation.testListInput"), get_argument_nodes("input: { string: $string2 }"), nil))
    assert_equal_input({input: [{ string: "nested" }]}, input.argument_values(TestSchema.find("Mutation.testListInput"), get_argument_nodes("input: $input"), nil))
    assert_equal_input({input: [{}, {string: "Str"}, {string: "abc"}, {string: "xyz"}, {string: "nested"}]}, input.argument_values(TestSchema.find("Mutation.testListInput"), get_argument_nodes("input: [{string: $s}, {string: \"Str\"}, {string: $string }, { string: $string2 }, $input]"), nil))
  end
end
