# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Field::ConnectionExtension do
  class ConnectionShortcutSchema < GraphQL::Schema
    class ShortcutResolveExtension < GraphQL::Schema::FieldExtension
      def resolve(**rest)
        ["a", "b", "c", "d", "e"]
      end
    end
    class Query < GraphQL::Schema::Object
      field :names, GraphQL::Types::String.connection_type, null: false, extensions: [ShortcutResolveExtension]
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
end
