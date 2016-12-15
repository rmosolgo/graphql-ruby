# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Query::Variables do
  let(:query_string) {%|
  query getCheese($animals: [DairyAnimal!], $int: Int, $intWithDefault: Int = 10) {
    cheese(id: 1) {
      similarCheese(source: $animals)
    }
  }
  |}
  let(:ast_variables) { GraphQL.parse(query_string).definitions.first.variables }
  let(:schema) { DummySchema }
  let(:variables) { GraphQL::Query::Variables.new(
    schema,
    GraphQL::Schema::Warden.new(OpenStruct.new(schema: schema, context: nil), schema.default_mask),
    ast_variables,
    provided_variables)
  }

  describe "#initialize" do
    describe "coercing inputs" do
      let(:provided_variables) { { "animals" => "YAK" } }

      it "coerces single items into one-element lists" do
        assert_equal ["YAK"], variables["animals"]
      end
    end

    describe "nullable variables" do
      let(:schema) { GraphQL::Schema.from_definition(%|
        type Query {
          thingsCount(ids: [ID!]): Int!
        }
      |)
      }
      let(:query_string) {%|
        query getThingsCount($ids: [ID!]) {
          thingsCount(ids: $ids)
        }
      |}
      let(:result) {
        schema.execute(query_string, variables: provided_variables, root_value: OpenStruct.new(thingsCount: 1))
      }

      describe "when they are present, but null" do
        let(:provided_variables) { { "ids" => nil } }
        it "ignores them" do
          assert_equal 1, result["data"]["thingsCount"]
        end
      end

      describe "when they are not present" do
        let(:provided_variables) { {} }
        it "ignores them" do
          assert_equal 1, result["data"]["thingsCount"]
        end
      end

      describe "when a nullable list has a null in it" do
        let(:provided_variables) { { "ids" => [nil] } }
        it "returns an error" do
          assert_equal 1, result["errors"].length
          assert_equal nil, result["data"]
        end
      end
    end

    describe "coercing null" do
      let(:provided_variables) {
        {"int" => nil, "intWithDefault" => nil}
      }

      it "null variable" do
        assert_equal nil, variables["int"]
      end

      it "preserves explicit null when variable has a default value" do
        assert_equal nil, variables["intWithDefault"]
      end
    end
  end
end
