# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Argument do
  class SchemaArgumentTest < GraphQL::Schema::Object
    field :field, String, null: false do
      argument :arg, String, description: "test", required: false

      argument :arg_with_block, String, required: false do
        description "test"
      end
    end
  end

  describe "#name" do
    it "reflects camelization" do
      assert_equal "argWithBlock", SchemaArgumentTest.fields["field"].arguments["argWithBlock"].name
    end
  end

  describe "#type" do
    let(:argument) { SchemaArgumentTest.fields["field"].arguments["arg"] }
    it "returns the type" do
      assert_equal GraphQL::STRING_TYPE, argument.type
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
