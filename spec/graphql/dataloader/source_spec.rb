# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Dataloader::Source do
  class FailsToLoadSource < GraphQL::Dataloader::Source
    def fetch(keys)
      dataloader.with(FailsToLoadSource).load_all(keys)
    end
  end

  it "raises an error when it tries too many times to sync" do
    dl = GraphQL::Dataloader.new
    dl.append_job { dl.with(FailsToLoadSource).load(1) }
    err = assert_raises RuntimeError do
      dl.run
    end
    expected_message = "FailsToLoadSource#sync tried 1000 times to load pending keys ([1]), but they still weren't loaded. There is likely a circular dependency."
    assert_equal expected_message, err.message
  end

  it "is pending when waiting for false and nil" do
    dl = GraphQL::Dataloader.new
    dl.with(FailsToLoadSource).request(nil)

    source_cache = dl.instance_variable_get(:@source_cache)
    assert source_cache[FailsToLoadSource][[{}]].pending?
  end

  class NoDataloaderSchema < GraphQL::Schema
    class ThingSource < GraphQL::Dataloader::Source
      def fetch(ids)
        ids.map { |id| { name: "Thing-#{id}" } }
      end
    end

    class Thing < GraphQL::Schema::Object
      field :name, String
    end

    class Query < GraphQL::Schema::Object
      field :thing, Thing do
        argument :id, ID
      end

      def thing(id:)
        context.dataloader.with(ThingSource).load(id)
      end
    end
    query(Query)
  end

  it "raises an error when used without a dataloader" do
    err = assert_raises GraphQL::Error do
      NoDataloaderSchema.execute("{ thing(id: 1) { name } }")
    end

    expected_message = "GraphQL::Dataloader is not running -- add `use GraphQL::Dataloader` to your schema to use Dataloader sources."
    assert_equal expected_message, err.message
  end
end
