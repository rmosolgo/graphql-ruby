# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Pagination::Connections do
  ITEMS = ConnectionAssertions::NAMES.map { |n| { name: n } }

  class ArrayConnectionWithTotalCount < GraphQL::Pagination::ArrayConnection
    def total_count
      items.size
    end
  end

  let(:base_schema) {
    ConnectionAssertions.build_schema(
      connection_class: GraphQL::Pagination::ArrayConnection,
      total_count_connection_class: ArrayConnectionWithTotalCount,
      get_items: -> { ITEMS }
    )
  }

  # These wouldn't _work_, I just need to test `.wrap`
  class SetConnection < GraphQL::Pagination::ArrayConnection; end
  class HashConnection < GraphQL::Pagination::ArrayConnection; end
  class OtherArrayConnection < GraphQL::Pagination::ArrayConnection; end

  let(:schema) do
    other_base_schema = Class.new(base_schema) do
      connections.add(Set, SetConnection)
    end

    Class.new(other_base_schema) do
      connections.add(Hash, HashConnection)
      connections.add(Array, OtherArrayConnection)
    end
  end

  it "returns connections by class, using inherited mappings and local overrides" do
    field_defn = OpenStruct.new(max_page_size: 10, type: GraphQL::Types::Relay::BaseConnection)

    set_wrapper = schema.connections.wrap(field_defn, nil, Set.new([1,2,3]), {}, nil)
    assert_instance_of SetConnection, set_wrapper

    hash_wrapper = schema.connections.wrap(field_defn, nil, {1 => :a, 2 => :b}, {}, nil)
    assert_instance_of HashConnection, hash_wrapper

    array_wrapper = schema.connections.wrap(field_defn, nil, [1,2,3], {}, nil)
    assert_instance_of OtherArrayConnection, array_wrapper
  end

  it "uses passed-in wrappers" do
    field_defn = OpenStruct.new(max_page_size: 10)

    assert_raises GraphQL::Pagination::Connections::ImplementationMissingError do
      schema.connections.wrap(field_defn, nil, Set.new([1,2,3]), {}, nil, wrappers: {})
    end
  end

  # Simulate a schema with a `*Connection` type that _isn't_
  # supposed to be a connection. Help debug, see https://github.com/rmosolgo/graphql-ruby/issues/2588
  class ConnectionErrorTestSchema < GraphQL::Schema
    use GraphQL::Execution::Interpreter
    use GraphQL::Analysis::AST
    use GraphQL::Pagination::Connections

    class BadThing
      def name
        self.no_such_method # raise a NoMethodError
      end

      def inspect
        "<BadThing!>"
      end
    end

    class ThingConnection < GraphQL::Schema::Object
      field :name, String, null: false
    end

    class Query < GraphQL::Schema::Object
      field :things, [ThingConnection], null: false

      def things
        [{name: "thing1"}, {name: "thing2"}]
      end

      field :things2, [ThingConnection], null: false, connection: false

      def things2
        [
          BadThing.new
        ]
      end
    end

    query(Query)
  end

  it "raises a helpful error when it fails to implement a connection" do
    err = assert_raises GraphQL::Execution::Interpreter::ListResultFailedError do
      pp ConnectionErrorTestSchema.execute("{ things { name } }")
    end

    assert_includes err.message, "Failed to build a GraphQL list result for field `Query.things` at path `things`."
    assert_includes err.message, "to implement `.each` to satisfy the GraphQL return type `[ThingConnection!]!`"
    assert_includes err.message, "This field was treated as a Relay-style connection; add `connection: false` to the `field(...)` to disable this behavior."
  end

  it "lets unrelated NoMethodErrors bubble up" do
    err = assert_raises NoMethodError do
      pp ConnectionErrorTestSchema.execute("{ things2 { name } }")
    end

    assert_includes err.message, "undefined method `no_such_method' for <BadThing!>"
  end

  class SingleNewConnectionSchema < GraphQL::Schema
    class Query < GraphQL::Schema::Object
      field :strings, GraphQL::Types::String.connection_type, null: false

      def strings
        GraphQL::Pagination::ArrayConnection.new(["a", "b", "c"])
      end
    end

    query(Query)
    use GraphQL::Execution::Interpreter
    use GraphQL::Analysis::AST
  end

  it "works when new connections are not installed" do
    res = SingleNewConnectionSchema.execute("{ strings(first: 2) { edges { node } } }")
    assert_equal ["a", "b"], res["data"]["strings"]["edges"].map { |e| e["node"] }
  end
end
