# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Function do
  class TestFunc < GraphQL::Function
    argument :name, GraphQL::STRING_TYPE
    argument :age, types.Int
    type do
      name "TestFuncPayload"
      field :name, types.String, hash_key: :name
    end

    description "Returns the string you give it"
    deprecation_reason "It's useless"
    complexity 9
    def call(o, a, c)
      { name: a[:name] }
    end
  end

  describe "function API" do
    it "exposes required info" do
      f = TestFunc.new
      assert_equal ["name", "age"], f.arguments.keys
      assert_equal "TestFuncPayload", f.type.name
      assert_equal "Returns the string you give it", f.description
      assert_equal "It's useless", f.deprecation_reason
      assert_equal({name: "stuff"}, f.call(nil, { name: "stuff" }, nil))
      assert_equal 9, f.complexity

      assert_equal TestFunc.new.type, TestFunc.new.type
    end
  end

  it "has default values" do
    default_func = GraphQL::Function.new
    assert_equal 1, default_func.complexity
    assert_equal({}, default_func.arguments)
    assert_equal(nil, default_func.type)
    assert_equal(nil, default_func.description)
    assert_equal(nil, default_func.deprecation_reason)
    assert_raises(NotImplementedError) {
      default_func.call(nil, nil, nil)
    }
  end

  describe "use in a schema" do
    let(:schema) {
      query_type = GraphQL::ObjectType.define do
        name "Query"
        field :test, function: TestFunc.new
        connection :testConn, function: TestFunc.new
      end

      relay_mutation = GraphQL::Relay::Mutation.define do
        name "Test"
        function TestFunc.new
      end

      mutation_type = GraphQL::ObjectType.define do
        name "Mutation"
        field :test, field: relay_mutation.field
      end

      GraphQL::Schema.define do
        query(query_type)
        mutation(mutation_type)
      end
    }

    it "gets attributes from the function" do
      field = schema.query.fields["test"]
      assert_equal ["name", "age"], field.arguments.keys
      assert_equal "TestFuncPayload", field.type.name
      assert_equal "Returns the string you give it", field.description
      assert_equal "It's useless", field.deprecation_reason
      assert_equal({name: "stuff"}, field.resolve(nil, { name: "stuff" }, nil))
      assert_equal 9, field.complexity
    end

    it "can be used as a field" do
      query_str = <<-GRAPHQL
      { test(name: "graphql") { name }}
      GRAPHQL
      res = schema.execute(query_str)
      assert_equal "graphql", res["data"]["test"]["name"]
    end

    it "can be used as a mutation" do
      query_str = <<-GRAPHQL
      mutation { test(input: {clientMutationId: "123", name: "graphql"}) { name, clientMutationId } }
      GRAPHQL
      res = schema.execute(query_str)
      assert_equal "graphql", res["data"]["test"]["name"]
    end
  end

  describe "when overriding" do
    let(:schema) {
      query_type = GraphQL::ObjectType.define do
        name "Query"
        field :blockOverride, function: TestFunc.new do
          description "I have altered the description"
          argument :anArg, types.Int
          argument :oneMoreArg, types.String
        end

        field :argOverride, types.String, "New Description", function: TestFunc.new
      end

      GraphQL::Schema.define do
        query(query_type)
      end
    }

    it "can override description" do
      field = schema.query.fields["blockOverride"]
      assert_equal "I have altered the description", field.description
      assert_equal ["name", "age", "anArg", "oneMoreArg"], field.arguments.keys
    end

    it "can add to arguments" do
      field = schema.query.fields["argOverride"]
      assert_equal "New Description", field.description
      assert_equal GraphQL::STRING_TYPE, field.type
      assert_equal ["name", "age"], field.arguments.keys
    end
  end
end
