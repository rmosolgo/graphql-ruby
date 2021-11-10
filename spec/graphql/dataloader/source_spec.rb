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
end
