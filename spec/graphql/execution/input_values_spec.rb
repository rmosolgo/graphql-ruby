# frozen_string_literal: true
require "spec_helper"

class ExecutionInputValuesTest < Minitest::Test
  TEST_SCHEMA = GraphQL::Schema.from_definition(%|
    enum TestStatus {
      ACTIVE
      INACTIVE
    }

    input TestInput {
      string: String
      float: Float
      int: Int
      enum: TestStatus
    }

    type Mutation {
      testInput(input: TestInput): Boolean
    }

    type Query {
      ping: Boolean
    }
  |)


  class DummyRunner
    def add_step(s); end
    def schema; TEST_SCHEMA; end
  end

  def get_input_values(variables_string: "", variables: nil)
    query_str = "query#{variables_string ? "(#{variables_string})" : ""} { __typename }"
    query = GraphQL::Query.new(TEST_SCHEMA, query_str, validate: false, variables: variables)
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
    assert_equal( { if: false }, input.argument_values(GraphQL::Schema::Directive::Skip, get_argument_nodes("if: $if"), nil))
    assert_equal( { if: true }, input.argument_values(GraphQL::Schema::Directive::Skip, get_argument_nodes("if: true"), nil))
  end

  def test_it_produces_argument_values_for_input_objects
    input = get_input_values
    assert_equal({input: { string: "a", enum: "ACTIVE" } }, input.argument_values(TEST_SCHEMA.find("Mutation.testInput"), get_argument_nodes("input: { string: \"a\", enum: ACTIVE }"), nil))
  end
end
