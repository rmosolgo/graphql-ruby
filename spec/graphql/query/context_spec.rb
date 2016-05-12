require "spec_helper"

describe GraphQL::Query::Context do
  let(:query_type) { GraphQL::ObjectType.define {
    field :context, types.String do
      argument :key, !types.String
      resolve -> (target, args, ctx) { ctx[args[:key]] }
    end
    field :contextAstNodeName, types.String do
      resolve -> (target, args, ctx) { ctx.ast_node.class.name }
    end

    field :queryName, types.String do
      resolve -> (target, args, ctx) { ctx.query.class.name }
    end
  }}
  let(:schema) { GraphQL::Schema.new(query: query_type, mutation: nil)}
  let(:result) { schema.execute(query_string, context: {"some_key" => "some value"})}

  describe "access to passed-in values" do
    let(:query_string) { %|
      query getCtx { context(key: "some_key") }
    |}

    it "passes context to fields" do
      expected = {"data" => {"context" => "some value"}}
      assert_equal(expected, result)
    end
  end

  describe "access to the AST node" do
    let(:query_string) { %|
      query getCtx { contextAstNodeName }
    |}

    it "provides access to the AST node" do
      expected = {"data" => {"contextAstNodeName" => "GraphQL::Language::Nodes::Field"}}
      assert_equal(expected, result)
    end
  end

  describe "access to the query" do
    let(:query_string) { %|
      query getCtx { queryName }
    |}

    it "provides access to the AST node" do
      expected = {"data" => {"queryName" => "GraphQL::Query::Run"}}
      assert_equal(expected, result)
    end
  end

  describe "empty values" do
    let(:context) { GraphQL::Query::Context.new(query: OpenStruct.new(schema: schema), values: nil) }

    it "returns nil for any key" do
      assert_equal(nil, context[:some_key])
    end
  end
end
