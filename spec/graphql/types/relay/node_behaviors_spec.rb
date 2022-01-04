# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Types::Relay::NodeBehaviors do
  class NodeBehaviorsSchema < GraphQL::Schema
    class Thing < GraphQL::Schema::Object
      implements GraphQL::Types::Relay::Node
    end

    class Query < GraphQL::Schema::Object
      field :thing, Thing

      def thing
        {}
      end
    end

    query(Query)

    def self.id_from_object(obj, _type, _ctx)
      "blah"
    end
  end

  it "adds an `id` field that calls `schema.id_from_object`" do
    res = NodeBehaviorsSchema.execute("{ thing { id } }")
    assert_equal "blah", res["data"]["thing"]["id"]
  end
end
