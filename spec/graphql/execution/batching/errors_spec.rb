# frozen_string_literal: true
require "spec_helper"
require "graphql/execution/batching"

class ErrorResultFormatterTest < Minitest::Test
  class HashKeyResolver
    def initialize(key)
      @key = key
    end

    def call(obj, ctx)
      obj[@key]
    end
  end
  RESOLVE_TYPE = ->(abs_type, obj, ctx) { ctx.types.get_type("Test") }
  TEST_RESOLVERS = {
    "Node" => {
      "id" => HashKeyResolver.new("id"),
      "__type__" => ->(obj, ctx) { ctx.types.type(obj["__typename__"]) },
    },
    "Test" => {
      "id" => HashKeyResolver.new("id"),
      "req" => HashKeyResolver.new("req"),
      "opt" => HashKeyResolver.new("opt"),
    },
    "Query" => {
      "node" => HashKeyResolver.new("node"),
      "test" => HashKeyResolver.new("test"),
      "reqField" => HashKeyResolver.new("reqField"),
      "anotherField" => HashKeyResolver.new("anotherField"),
    },
  }.freeze

  module DefaultResolve
    def self.resolve_type(abs_t, obj, ctx)
      ctx.types.type("Test")
    end

    def self.call(object_type, field_definition, object, arguments, context)
      TEST_RESOLVERS.fetch(object_type.graphql_name).fetch(field_definition.graphql_name).call(object, context)
    end
  end

  def exec_test(schema_str, query_str, data)
    schema = GraphQL::Schema.from_definition(schema_str, default_resolve: DefaultResolve)
    schema.execute_batching(query_str, root_value: data)
  end

  def test_basic_object_structure
    schema = "type Test { req: String! opt: String } type Query { test: Test }"
    source = {
      "test" => {
        "req" => "yes",
        "opt" => nil
      }
    }
    expected = {
      "data" => {
        "test" => {
          "req" => "yes",
          "opt" => nil
        }
      }
    }

    assert_equal expected, exec_test(schema, "{ test { req opt } }", source)
  end

  def test_errors_render_above_data_in_result
    schema = "type Test { req: String! opt: String } type Query { test: Test }"
    source = { "test" => { "req" => nil } }

    assert_equal ["errors", "data"], exec_test(schema, "{ test { req } }", source).keys
  end

  def test_bubbles_null_for_single_object_scopes
    schema = "type Test { req: String! opt: String } type Query { test: Test }"
    source = {
      "test" => {
        "req" => nil,
        "opt" => "yes"
      },
    }
    expected = {
      "data" => {
        "test" => nil,
      },
      "errors" => [{
        "message" => "Cannot return null for non-nullable field Test.req",
        "path" => ["test", "req"],
        "locations" => [{ "line" => 1, "column" => 10 }],
      }],
    }

    assert_equal expected, exec_test(schema, "{ test { req opt } }", source)
  end

  def test_bubbles_null_for_nested_non_null_object_scopes
    schema = "type Test { req: String! opt: String } type Query { test: Test! }"
    source = {
      "test" => {
        "req" => nil,
        "opt" => "yes"
      }
    }
    expected = {
      "data" => nil,
      "errors" => [{
        "message" => "Cannot return null for non-nullable field Test.req",
        "path" => ["test", "req"],
        "locations" => [{ "line" => 1, "column" => 10 }],
      }],
    }

    assert_equal expected, exec_test(schema, "{ test { req opt } }", source)
  end

  def test_basic_list_structure
    schema = "type Test { req: String! opt: String } type Query { test: [Test] }"
    source = {
      "test" => [
        { "req" => "yes", "opt" => nil },
        { "req" => "yes", "opt" => "yes" },
      ],
    }
    expected = {
      "data" => {
        "test" => [
          { "req" => "yes", "opt" => nil },
          { "req" => "yes", "opt" => "yes" },
        ],
      },
    }

    assert_equal expected, exec_test(schema, "{ test { req opt } }", source)
  end

  def test_bubbles_null_for_list_elements
    schema = "type Test { req: String! opt: String } type Query { test: [Test] }"
    source = {
      "test" => [
        { "req" => "yes", "opt" => nil },
        { "req" => nil, "opt" => "yes" },
      ],
    }
    expected = {
      "data" => {
        "test" => [
          { "req" => "yes", "opt" => nil },
          nil,
        ],
      },
      "errors" => [{
        "message" => "Cannot return null for non-nullable field Test.req",
        "path" => ["test", 1, "req"],
        "locations" => [{ "line" => 1, "column" => 10 }],
      }],
    }

    assert_equal expected, exec_test(schema, "{ test { req opt } }", source)
  end

  def test_bubbles_null_for_required_list_elements
    schema = "type Test { req: String! opt: String } type Query { test: [Test!] }"
    source = {
      "test" => [
        { "req" => "yes", "opt" => nil },
        { "req" => nil, "opt" => "yes" },
      ]
    }
    expected = {
      "data" => {
        "test" => nil,
      },
      "errors" => [{
        "message" => "Cannot return null for non-nullable field Test.req",
        "path" => ["test", 1, "req"],
        "locations" => [{ "line" => 1, "column" => 10 }],
      }],
    }

    assert_equal expected, exec_test(schema, "{ test { req opt } }", source)
  end

  def test_bubbles_null_for_required_lists
    schema = "type Test { req: String! opt: String } type Query { test: [Test!]! }"
    source = {
      "test" => [
        { "req" => "yes", "opt" => nil },
        { "req" => nil, "opt" => "yes" },
      ],
    }
    expected = {
      "data" => nil,
      "errors" => [{
        "message" => "Cannot return null for non-nullable field Test.req",
        "path" => ["test", 1, "req"],
        "locations" => [{ "line" => 1, "column" => 10 }],
      }],
    }

    assert_equal expected, exec_test(schema, "{ test { req opt } }", source)
  end

  def test_basic_nested_list_structure
    schema = "type Test { req: String! opt: String } type Query { test: [[Test]] }"
    source = {
      "test" => [
        [{ "req" => "yes", "opt" => nil }],
        [{ "req" => "yes", "opt" => "yes" }],
      ],
    }
    expected = {
      "data" => {
        "test" => [
          [{ "req" => "yes", "opt" => nil }],
          [{ "req" => "yes", "opt" => "yes" }],
        ],
      },
    }

    assert_equal expected, exec_test(schema, "{ test { req opt } }", source)
  end

  def test_bubbles_null_for_nested_list_elements
    schema = "type Test { req: String! opt: String } type Query { test: [[Test]] }"
    source = {
      "test" => [
        [{ "req" => "yes", "opt" => nil }],
        [{ "req" => nil, "opt" => "yes" }],
      ],
    }
    expected = {
      "data" => {
        "test" => [
          [{ "req" => "yes", "opt" => nil }],
          [nil],
        ],
      },
      "errors" => [{
        "message" => "Cannot return null for non-nullable field Test.req",
        "path" => ["test", 1, 0, "req"],
        "locations" => [{ "line" => 1, "column" => 10 }],
      }],
    }

    assert_equal expected, exec_test(schema, "{ test { req opt } }", source)
  end

  def test_bubbles_null_for_nested_required_list_elements
    schema = "type Test { req: String! opt: String } type Query { test: [[Test!]] }"
    source = {
      "test" => [
        [{ "req" => "yes", "opt" => nil }],
        [{ "req" => nil, "opt" => "yes" }],
      ],
    }
    expected = {
      "data" => {
        "test" => [
          [{ "req" => "yes", "opt" => nil }],
          nil,
        ],
      },
      "errors" => [{
        "message" => "Cannot return null for non-nullable field Test.req",
        "path" => ["test", 1, 0, "req"],
        "locations" => [{ "line" => 1, "column" => 10 }],
      }],
    }

    assert_equal expected, exec_test(schema, "{ test { req opt } }", source)
  end

  def test_bubbles_null_for_inner_required_lists
    schema = "type Test { req: String! opt: String } type Query { test: [[Test!]!] }"
    source = {
      "test" => [
        [{ "req" => "yes", "opt" => nil }],
        [{ "req" => nil, "opt" => "yes" }],
      ],
    }
    expected = {
      "data" => {
        "test" => nil,
      },
      "errors" => [{
        "message" => "Cannot return null for non-nullable field Test.req",
        "path" => ["test", 1, 0, "req"],
        "locations" => [{ "line" => 1, "column" => 10 }],
      }],
    }

    assert_equal expected, exec_test(schema, "{ test { req opt } }", source)
  end

  def test_bubbles_null_through_nested_required_list_scopes
    schema = "type Test { req: String! opt: String } type Query { test: [[Test!]!]! }"
    source = {
      "test" => [
        [{ "req" => "yes", "opt" => nil }],
        [{ "req" => nil, "opt" => "yes" }],
      ],
    }
    expected = {
      "data" => nil,
      "errors" => [{
        "message" => "Cannot return null for non-nullable field Test.req",
        "path" => ["test", 1, 0, "req"],
        "locations" => [{ "line" => 1, "column" => 10 }],
      }],
    }

    assert_equal expected, exec_test(schema, "{ test { req opt } }", source)
  end

  def test_bubble_through_inline_fragment
    schema = "type Test { req: String! opt: String } type Query { test: Test }"
    source = {
      "test" => {
        "req" => nil,
        "opt" => nil
      },
    }
    expected = {
      "data" => {
        "test" => nil,
      },
      "errors" => [{
        "message" => "Cannot return null for non-nullable field Test.req",
        "path" => ["test", "req"],
        "locations" => [{ "line" => 1, "column" => 10 }],
      }],
    }

    assert_equal expected, exec_test(schema, "{ test { req opt } }", source)
  end

  def test_bubble_through_fragment_spreads
    schema = "type Test { req: String! opt: String } type Query { test: Test }"
    source = {
      "test" => {
        "req" => nil,
        "opt" => nil
      },
    }
    expected = {
      "data" => {
        "test" => nil,
      },
      "errors" => [{
        "message" => "Cannot return null for non-nullable field Test.req",
        "path" => ["test", "req"],
        "locations" => [{ "line" => 1, "column" => 10 }],
      }],
    }

    assert_equal expected, exec_test(schema, "{ test { req opt } }", source)
  end

  def test_inline_errors_in_null_positions_report
    schema = "type Test { req: String! opt: String } type Query { test: [Test] }"
    source = {
      "test" => [
        { "req" => "yes", "opt" => nil },
        { "req" => "yes", "opt" => GraphQL::ExecutionError.new("Not okay!") },
      ],
    }
    expected = {
      "data" => {
        "test" => [
          { "req" => "yes", "opt" => nil },
          { "req" => "yes", "opt" => nil },
        ],
      },
      "errors" => [{
        "message" => "Not okay!",
        "locations" => [{ "line" => 1, "column" => 14 }],
        "path" => ["test", 1, "opt"],
      }],
    }

    assert_equal expected, exec_test(schema, "{ test { req opt } }", source)

    inline_fragment_errors = [{
      "message" => "Not okay!",
      "locations" => [{ "line" => 1, "column" => 28 }],
      "path" => ["test", 1, "opt"],
    }]

    result = exec_test(schema, "{ ...on Query { test { req opt } } }", source)
    assert_equal expected["data"], result["data"]
    assert_equal inline_fragment_errors, result["errors"]

    fragment_errors = [{
      "message" => "Not okay!",
      "locations" => [{ "line" => 1, "column" => 59 }],
      "path" => ["test", 1, "opt"],
    }]

    result = exec_test(schema, "{ ...Selection } fragment Selection on Query { test { req opt } }", source)
    assert_equal expected["data"], result["data"]
    assert_equal fragment_errors, result["errors"]
  end

  def test_abstract_fragments_on_concrete_results_interpret_type
    schema = %|
      interface Node {
        id: ID!
      }
      type Test implements Node {
        id: ID!
      }
      type Query {
        node: Node
        test: Test
      }
    |

    query = %|
      query {
        test {
          ... on Node { id }
          ... NodeAttrs
        }
      }
      fragment NodeAttrs on Node { id }
    |

    source = {
      "test" => {},
    }

    expected = {
      "errors" => [{
        "message" => "Cannot return null for non-nullable field Test.id",
        "locations" => [{ "line" => 4, "column" => 25 }, { "line" => 8, "column" => 36 }],
        "path" => ["test", "id"],
      }],
      "data" => { "test" => nil },
    }

    assert_equal expected, exec_test(schema, query, source)
  end

  def test_concrete_fragments_on_abstract_results_interpret_type
    schema = %|
      interface Node {
        id: ID!
      }
      type Test implements Node {
        id: ID!
      }
      type Query {
        node: Node
        test: Test
      }
    |

    query = %|
      query {
        node {
          ... on Test { id }
          ... TestAttrs
        }
      }
      fragment TestAttrs on Test { id }
    |

    source = {
      "node" => { "__typename__" => "Test" },
    }

    expected = {
      "errors" => [{
        "message" => "Cannot return null for non-nullable field Test.id",
        "locations" => [{ "line" => 4, "column" => 25 }, { "line" => 8, "column" => 36 }],
        "path" => ["node", "id"],
      }],
      "data" => { "node" => nil },
    }

    assert_equal expected, exec_test(schema, query, source)
  end

  def test_inline_errors_in_non_null_positions_report_and_propagate
    schema = "type Test { req: String! opt: String } type Query { test: [Test] }"
    source = {
      "test" => [
        { "req" => "yes", "opt" => nil },
        { "req" => GraphQL::ExecutionError.new("Not okay!"), "opt" => nil },
      ],
    }
    expected = {
      "data" => {
        "test" => [
          { "req" => "yes", "opt" => nil },
          nil,
        ],
      },
      "errors" => [{
        "message" => "Not okay!",
        "locations" => [{ "line" => 1, "column" => 10 }],
        "path" => ["test", 1, "req"],
      }],
    }

    assert_equal expected, exec_test(schema, "{ test { req opt } }", source)
  end

  def test_multiple_offenses_for_null_position_report_all_instances
    schema = "type Test { req: String! opt: String } type Query { test: [Test] }"
    source = {
      "test" => [
        { "req" => "yes", "opt" => nil },
        { "req" => "yes", "opt" => GraphQL::ExecutionError.new("Not okay!") },
        { "req" => "yes", "opt" => GraphQL::ExecutionError.new("Not okay!") },
      ],
    }
    expected = {
      "data" => {
        "test" => [
          { "req" => "yes", "opt" => nil },
          { "req" => "yes", "opt" => nil },
          { "req" => "yes", "opt" => nil },
        ],
      },
      "errors" => [{
        "message" => "Not okay!",
        "locations" => [{ "line" => 1, "column" => 14 }],
        "path" => ["test", 1, "opt"],
      }, {
        "message" => "Not okay!",
        "locations" => [{ "line" => 1, "column" => 14 }],
        "path" => ["test", 2, "opt"],
      }],
    }

    assert_equal expected, exec_test(schema, "{ test { req opt } }", source)
  end

  def test_multiple_offenses_for_non_null_position_without_intersecting_propagation_report_all_instances
    schema = "type Test { req: String! opt: String } type Query { test: [Test] }"
    source = {
      "test" => [
        { "req" => "yes", "opt" => nil },
        { "req" => GraphQL::ExecutionError.new("Not okay!"), "opt" => "yes" },
        { "req" => GraphQL::ExecutionError.new("Not okay!"), "opt" => "yes" },
      ],
    }
    expected = {
      "data" => {
        "test" => [
          { "req" => "yes", "opt" => nil },
          nil,
          nil,
        ],
      },
      "errors" => [{
        "message" => "Not okay!",
        "locations" => [{ "line" => 1, "column" => 10 }],
        "path" => ["test", 1, "req"],
      }, {
        "message" => "Not okay!",
        "locations" => [{ "line" => 1, "column" => 10 }],
        "path" => ["test", 2, "req"],
      }],
    }

    assert_equal expected, exec_test(schema, "{ test { req opt } }", source)
  end

  def test_multiple_offenses_for_non_null_position_with_intersecting_propagation_report_first_instance
    schema = "type Test { req: String! opt: String } type Query { test: [Test!] }"
    source = {
      "test" => [
        { "req" => "yes", "opt" => nil },
        { "req" => GraphQL::ExecutionError.new("first"), "opt" => "yes" },
        { "req" => GraphQL::ExecutionError.new("second"), "opt" => "yes" },
      ],
    }
    expected = {
      "data" => {
        "test" => nil,
      },
      "errors" => [{
        "message" => "first",
        "locations" => [{ "line" => 1, "column" => 10 }],
        "path" => ["test", 1, "req"],
      },{
        "message" => "second",
        "locations" => [{ "line" => 1, "column" => 10 }],
        "path" => ["test", 2, "req"],
      }],
    }

    # The original Shopify spec only expected the _first_ error to be present,
    # because of how the query would be terminated when an error was encountered.
    # We might change this in the future to only return a single error.
    # See: https://github.com/rmosolgo/graphql-ruby/pull/5509#discussion_r2756873801
    assert_equal expected, exec_test(schema, "{ test { req opt } }", source)
  end

  def test_multiple_locations_for_duplicate_field_selections
    schema = "type Query { reqField: String! }"
    source = {
      "reqField" => nil,
    }

    query = <<~GRAPHQL
      {
        reqField
        reqField
      }
    GRAPHQL

    expected = {
      "data" => nil,
      "errors" => [{
        "message" => "Cannot return null for non-nullable field Query.reqField",
        "path" => ["reqField"],
        "locations" => [
          { "line" => 2, "column" => 3 },
          { "line" => 3, "column" => 3 },
        ],
      }],
    }

    assert_equal expected, exec_test(schema, query, source)
  end

  def test_multiple_locations_with_fragments
    schema = "type Query { reqField: String! anotherField: String }"
    source = {
      "reqField" => nil,
      "anotherField" => "value",
    }

    query = <<~GRAPHQL
      {
        reqField
        ...Fields
      }

      fragment Fields on Query {
        reqField
        anotherField
      }
    GRAPHQL

    expected = {
      "data" => nil,
      "errors" => [{
        "message" => "Cannot return null for non-nullable field Query.reqField",
        "path" => ["reqField"],
        "locations" => [
          { "line" => 2, "column" => 3 },
          { "line" => 7, "column" => 3 },
        ],
      }],
    }

    assert_equal expected, exec_test(schema, query, source)
  end

  def test_multiple_locations_with_inline_fragments
    schema = "type Query { reqField: String! }"
    source = {
      "reqField" => nil,
    }

    query = <<~GRAPHQL
      {
        reqField
        ... on Query {
          reqField
        }
      }
    GRAPHQL

    expected = {
      "data" => nil,
      "errors" => [{
        "message" => "Cannot return null for non-nullable field Query.reqField",
        "path" => ["reqField"],
        "locations" => [
          { "line" => 2, "column" => 3 },
          { "line" => 4, "column" => 5 },
        ],
      }],
    }

    assert_equal expected, exec_test(schema, query, source)
  end

  def test_formats_errors_with_extensions
    schema = "type Query { test: String! }"
    source = {
      "test" => GraphQL::ExecutionError.new("Not okay!", extensions: {
        "code" => "TEST",
        reason: "sorry",
      })
    }
    expected = {
      "data" => nil,
      "errors" => [{
        "message" => "Not okay!",
        "locations" => [{ "line" => 1, "column" => 3 }],
        "extensions" => { "code" => "TEST", "reason" => "sorry" },
        "path" => ["test"],
      }],
    }

    assert_equal expected, exec_test(schema, "{ test }", source)
  end

  def test_formats_error_message_for_non_null_list_items
    schema = "type Test { req: String! } type Query { test: [Test!]! }"
    source = {
      "test" => [nil],
    }
    expected = {
      "data" => nil,
      "errors" => [{
        "message" => "Cannot return null for non-nullable element of type 'Test!' for Query.test",
        "path" => ["test", 0],
        "locations" => [{ "line" => 1, "column" => 3 }],
      }],
    }

    assert_equal expected, exec_test(schema, "{ test { req } }", source)
  end
end
