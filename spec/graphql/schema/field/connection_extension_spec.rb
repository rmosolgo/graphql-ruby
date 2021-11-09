# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Field::ConnectionExtension do
  class ConnectionShortcutSchema < GraphQL::Schema
    class ShortcutResolveExtension < GraphQL::Schema::FieldExtension
      def resolve(arguments:, **rest)
        collection = ["a", "b", "c", "d", "e"]
        if (filter = arguments[:starting_with])
          collection.select! { |x| x.start_with?(filter) }
        end
        collection
      end
    end

    class CustomStringConnection < GraphQL::Types::Relay::BaseConnection
      edge_type(GraphQL::Types::String.edge_type)
      field :argument_data, [String], null: false

      def argument_data
        [object.arguments.class.name, *object.arguments.keys.map(&:inspect)]
      end
    end

    class Query < GraphQL::Schema::Object
      field :names, CustomStringConnection, null: false, extensions: [ShortcutResolveExtension] do
        argument :starting_with, String, required: false
      end

      def names
        raise "This should never be called"
      end
    end

    query(Query)
  end

  it "implements connection handling even when resolve is shortcutted" do
    res = ConnectionShortcutSchema.execute("{ names(first: 2) { nodes } }")
    assert_equal ["a", "b"], res["data"]["names"]["nodes"]
  end

  it "assigns arguments to the connection instance" do
    res = ConnectionShortcutSchema.execute("{ names(first: 2, startingWith: \"a\") { nodes argumentData } }")
    assert_equal ["a"], res["data"]["names"]["nodes"]
    # This come through as symbols
    assert_equal ["Hash", ":first", ":starting_with"], res["data"]["names"]["argumentData"]
  end

  class LegacyConnectionSchema < GraphQL::Schema
    Thing = Struct.new(:name)
    class ThingList < SimpleDelegator
    end

    class ThingType < GraphQL::Schema::Object
      field :name, String, null: false
    end

    class Query < GraphQL::Schema::Object
      field :things, ThingType.connection_type, null: false

      def things
        ThingList.new([Thing.new("A"), Thing.new("B"), Thing.new("C")])
      end
    end

    class ThingConnection < GraphQL::Relay::ArrayConnection
    end

    GraphQL::Relay::BaseConnection.register_connection_implementation(ThingList, ThingConnection)

    query(Query)
  end

  it "falls back to legacy connections" do
    res = nil
    _stdout, stderr = capture_io do
      res = LegacyConnectionSchema.execute("{ things { edges { node { name } } } }")
    end
    assert_includes stderr, "will be removed from GraphQL-Ruby 2.0"
    thing_names = res["data"]["things"]["edges"].map { |e| e["node"]["name"] }
    assert_equal ["A", "B", "C"], thing_names
  end
end
