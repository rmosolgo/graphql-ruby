# frozen_string_literal: true
require "spec_helper"

describe "Next Execution field authorization" do
  class NextFieldAuthorizationSchema < GraphQL::Schema
    FETCHES = []

    class AllowedIdsSource < GraphQL::Dataloader::Source
      def fetch(ids)
        FETCHES << ids
        ids.map(&:odd?)
      end
    end

    class AuthorizedField < GraphQL::Schema::Field
      def authorized?(object, args, context)
        if object.id == 4 && context[:raise_on_four]
          raise ArgumentError, "Can't authorize 4"
        end
        super && context.dataloader.with(AllowedIdsSource).load(object.id)
      end
    end

    class Item < GraphQL::Schema::Object
      field :id, Integer
      field_class AuthorizedField
      field :secret, String
    end

    class Query < GraphQL::Schema::Object
      field :items, [Item], resolve_static: :items

      def self.items(context)
        (1..4).map { |id| OpenStruct.new(id: id, secret: "secret-#{id}") }
      end
    end

    query(Query)
    use GraphQL::Dataloader
    use GraphQL::Execution::Next

    def self.unauthorized_field(err)
      if err.context[:replace_denied]
        OpenStruct.new(id: err.object.id, secret: "redacted")
      else
        super
      end
    end

    rescue_from(ArgumentError) { |err| raise GraphQL::ExecutionError, err.message }
  end

  def run_next(context = {})
    NextFieldAuthorizationSchema::FETCHES.clear
    NextFieldAuthorizationSchema.execute_next("{ items { id secret } }", context: context).to_h
  end

  it "batches Dataloader loads made by field authorized? across objects" do
    result = run_next
    assert_equal [[1, 2, 3, 4]], NextFieldAuthorizationSchema::FETCHES
    assert_equal ["secret-1", nil, "secret-3", nil], result["data"]["items"].map { |i| i["secret"] }
    assert_equal [1, 3], result["data"]["items"].map { |i| i["id"] }.values_at(0, 2)
  end

  it "applies unauthorized_field for denied objects" do
    result = run_next(replace_denied: true)
    assert_equal [[1, 2, 3, 4]], NextFieldAuthorizationSchema::FETCHES
    assert_equal ["secret-1", "redacted", "secret-3", "redacted"], result["data"]["items"].map { |i| i["secret"] }
  end

  it "handles errors raised by authorized? with rescue_from" do
    result = run_next(raise_on_four: true)
    assert_equal ["Can't authorize 4"], result["errors"].map { |e| e["message"] }
  end
end
