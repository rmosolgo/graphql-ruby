# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::TypeExpression do
  let(:types) { Dummy::Schema.types }
  let(:ast_node) {
    document = GraphQL.parse("query dostuff($var: #{type_name}) { id } ")
    document.definitions.first.variables.first.type
  }
  let(:type_expression_result) { GraphQL::Schema::TypeExpression.build_type(types, ast_node) }

  describe "#type" do
    describe "simple types" do
      let(:type_name) { "DairyProductInput" }
      it "it gets types from the provided types" do
        assert_equal(Dummy::DairyProductInputType, type_expression_result)
      end
    end

    describe "non-null types" do
      let(:type_name) { "String!"}
      it "makes non-null types" do
        assert_equal(GraphQL::STRING_TYPE.to_non_null_type,type_expression_result)
      end
    end

    describe "list types" do
      let(:type_name) { "[DairyAnimal!]!" }

      it "makes list types" do
        expected = Dummy::DairyAnimalEnum
          .to_non_null_type
          .to_list_type
          .to_non_null_type
        assert_equal(expected, type_expression_result)
      end
    end
  end
end
