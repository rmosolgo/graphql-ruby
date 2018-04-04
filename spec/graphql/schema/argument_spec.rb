# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Argument do
  class SchemaArgumentTest < GraphQL::Schema::Object
    field :field, String, null: false do
      argument :arg, String, description: "test", required: false

      argument :argWithBlock, String, required: false do
        description "test"
      end
    end
  end

  describe "graphql definition" do
    it "calls block" do
      assert_equal "test", SchemaArgumentTest.fields["field"].arguments["argWithBlock"].description
    end
  end

  describe "#description" do
    it "sets description" do
      SchemaArgumentTest.fields["field"].arguments["arg"].description "new description"
      assert_equal "new description", SchemaArgumentTest.fields["field"].arguments["arg"].description
    end

    it "returns description" do
      assert_equal "test", SchemaArgumentTest.fields["field"].arguments["argWithBlock"].description
    end
  end
end
