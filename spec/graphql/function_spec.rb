require "spec_helper"

describe GraphQL::Function do
  class TestFunc < GraphQL::Function
    argument :name, GraphQL::STRING_TYPE
    type do
      name "TestFuncPayload"
      field :name, types.String, hash_key: :name
    end

    description "Returns the string you give it"
    deprecation_reason "It's useless"
    complexity -> { 10 }
    def call(o, a, c)
      { name: a[:name] }
    end
  end

  describe "function API" do
    it "exposes required info" do
      f = TestFunc.new
      assert_equal ["name"], f.arguments.keys
      assert_equal "TestFuncPayload", f.type.name
      assert_equal "Returns the string you give it", f.description
      assert_equal "It's useless", f.deprecation_reason
      assert_equal({name: "stuff"}, f.call(nil, { name: "stuff" }, nil))
      assert_instance_of Proc, f.complexity

      assert_equal TestFunc.new.type, TestFunc.new.type
    end
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
      assert_equal ["name", "anArg", "oneMoreArg"], field.arguments.keys
    end

    it "can add to arguments" do
      field = schema.query.fields["argOverride"]
      assert_equal "New Description", field.description
      assert_equal GraphQL::STRING_TYPE, field.type
      assert_equal ["name"], field.arguments.keys
    end
  end
end
