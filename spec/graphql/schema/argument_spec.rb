# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Argument do
  module SchemaArgumentTest
    class Query < GraphQL::Schema::Object
      field :field, String, null: false do
        argument :arg, String, description: "test", required: false

        argument :arg_with_block, String, required: false do
          description "test"
        end

        argument :aliased_arg, String, required: false, as: :renamed
        argument :prepared_arg, Int, required: false, prepare: :multiply
      end

      def field(**args)
        args.inspect
      end

      def multiply(val)
        context[:multiply_by] * val
      end
    end

    class Schema < GraphQL::Schema
      query(Query)
    end
  end



  describe "#name" do
    it "reflects camelization" do
      assert_equal "argWithBlock", SchemaArgumentTest::Query.fields["field"].arguments["argWithBlock"].name
    end
  end

  describe "#type" do
    let(:argument) { SchemaArgumentTest::Query.fields["field"].arguments["arg"] }
    it "returns the type" do
      assert_equal GraphQL::Types::String, argument.type
    end
  end

  describe "graphql definition" do
    it "calls block" do
      assert_equal "test", SchemaArgumentTest::Query.fields["field"].arguments["argWithBlock"].description
    end
  end

  describe "#description" do
    let(:arg) { SchemaArgumentTest::Query.fields["field"].arguments["arg"] }
    it "sets description" do
      arg.description "new description"
      assert_equal "new description", arg.description
    end

    it "returns description" do
      assert_equal "test", SchemaArgumentTest::Query.fields["field"].arguments["argWithBlock"].description
    end

    it "has an assignment method" do
      arg.description = "another new description"
      assert_equal "another new description", arg.description
    end
  end

  describe "as:" do
    it "uses that Symbol for Ruby kwargs" do
      query_str = <<-GRAPHQL
      { field(aliasedArg: "x") }
      GRAPHQL

      res = SchemaArgumentTest::Schema.execute(query_str)
      # Make sure it's getting the renamed symbol:
      assert_equal '{:renamed=>"x"}', res["data"]["field"]
    end
  end

  describe "prepare:" do
    it "calls the method on the field's owner" do
      query_str = <<-GRAPHQL
      { field(preparedArg: 5) }
      GRAPHQL

      res = SchemaArgumentTest::Schema.execute(query_str, context: {multiply_by: 3})
      # Make sure it's getting the renamed symbol:
      assert_equal '{:prepared_arg=>15}', res["data"]["field"]
    end
  end
end
