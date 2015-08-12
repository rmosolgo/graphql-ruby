require 'spec_helper'

describe "GraphQL::Introspection::INTROSPECTION_QUERY" do
  let(:query_string) { GraphQL::Introspection::INTROSPECTION_QUERY }
  let(:result) { GraphQL::Query.new(DummySchema, query_string).result }

  it 'runs' do
    assert(result["data"])
  end
end
