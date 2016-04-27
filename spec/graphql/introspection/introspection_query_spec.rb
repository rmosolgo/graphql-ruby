require "spec_helper"

describe "GraphQL::Introspection::INTROSPECTION_QUERY" do
  let(:query_string) { GraphQL::Introspection::INTROSPECTION_QUERY }
  let(:result) { DummySchema.execute(query_string) }

  it "runs" do
    assert(result["data"])
  end
end
