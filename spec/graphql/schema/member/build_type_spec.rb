# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Member::BuildType do
  describe ".to_type_name" do
    it "works with lists and non-nulls" do
      t = Class.new(GraphQL::Schema::Object) do
        graphql_name "T"
      end

      req_t = GraphQL::Schema::NonNull.new(t)
      list_req_t = GraphQL::Schema::List.new(req_t)

      assert_equal "T", GraphQL::Schema::Member::BuildType.to_type_name(list_req_t)
    end
  end
end
