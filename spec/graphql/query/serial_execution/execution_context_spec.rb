require "spec_helper"

describe GraphQL::Query::SerialExecution::ExecutionContext do
  let(:query_string) { %|
    query getFlavor($cheeseId: Int!) {
      brie: cheese(id: 1)   { ...cheeseFields, taste: flavor }
    }
    fragment cheeseFields on Cheese { flavor }
  |}
  let(:debug) { false }
  let(:operation_name) { nil }
  let(:query_variables) { {"cheeseId" => 2} }
  let(:schema) { DummySchema }
  let(:query) { GraphQL::Query.new(
    schema,
    query_string,
    variables: query_variables,
    debug: debug,
    operation_name: operation_name,
  )}
  let(:execution_context) {
    GraphQL::Query::SerialExecution::ExecutionContext.new(query, nil)
  }

  describe "add_error" do
    let(:err) { StandardError.new("test") }
    let(:expected) { [err] }

    it "adds an error on the query context" do
      execution_context.add_error(err)
      assert_equal(expected, query.context.errors)
    end
  end

  describe "get_type" do
    it "returns the respective type from the schema" do
      type = execution_context.get_type("Dairy")
      assert_equal(DairyType, type)
    end
  end

  describe "get_field" do
    it "returns the respective field from the schema" do
      field = execution_context.get_field(DairyType, "cheese")
      assert_equal("cheese", field.name)
    end
  end

  describe "get_fragment" do
    it "returns a fragment on the query by name" do
      fragment = execution_context.get_fragment("cheeseFields")
      assert_equal("cheeseFields", fragment.name)
    end
  end
end
