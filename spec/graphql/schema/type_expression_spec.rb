require "spec_helper"

describe GraphQL::Schema::TypeExpression do
  let(:schema) { DummySchema }
  let(:ast_node) {
    document = GraphQL.parse("query dostuff($var: #{type_name}) { id } ")
    document.definitions.first.variables.first.type
  }
  let(:type_expression) { GraphQL::Schema::TypeExpression.new(schema, ast_node) }

  describe "#type" do
    describe "simple types" do
      let(:type_name) { "DairyProductInput" }
      it "it gets types from the schema" do
        assert_equal(DairyProductInputType, type_expression.type)
      end
    end

    describe "non-null types" do
      let(:type_name) { "String!"}
      it "makes non-null types" do
        assert_equal(GraphQL::STRING_TYPE.to_non_null_type, type_expression.type)
      end
    end

    describe "list types" do
      let(:type_name) { "[DairyAnimal!]!" }

      it "makes list types" do
        expected = DairyAnimalEnum
          .to_non_null_type
          .to_list_type
          .to_non_null_type
        assert_equal(expected, type_expression.type)
      end
    end
  end
end
