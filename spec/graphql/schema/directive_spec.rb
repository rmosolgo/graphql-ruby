# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Directive do
  class MultiWord < GraphQL::Schema::Directive
  end

  it "uses a downcased class name" do
    assert_equal "multiWord", MultiWord.graphql_name
  end
end
