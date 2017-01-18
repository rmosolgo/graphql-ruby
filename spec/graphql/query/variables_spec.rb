# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Query::Variables do
  let(:query_string) {%|
  query getCheese(
    $animals: [DairyAnimal!],
    $intDefaultNull: Int = null,
    $int: Int,
    $intWithDefault: Int = 10)
  {
    cheese(id: 1) {
      similarCheese(source: $animals)
    }
  }
  |}
  let(:ast_variables) { GraphQL.parse(query_string).definitions.first.variables }
  let(:schema) { Dummy::Schema }
  let(:variables) { GraphQL::Query::Variables.new(
    schema,
    GraphQL::Schema::Warden.new(schema.default_mask, schema: schema, context: nil),
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

      describe "when a non-nullable list has a null in it" do
        let(:provided_variables) { { "ids" => [nil] } }
        it "returns an error" do
          assert_equal 1, result["errors"].length
          assert_equal nil, result["data"]
        end
      end
    end

    describe "coercing null" do
      let(:provided_variables) {
        {"intWithVariable" => nil, "intWithDefault" => nil}
      }
      let(:args) { {} }
      let(:schema) {
        args_cache = args
        query_type = GraphQL::ObjectType.define do
          name "Query"
          field :variables_test, types.Int do
            argument :val, types.Int
            argument :val_with_default, types.Int, default_value: 13
            resolve ->(o, a, c) {
              args_cache[c.ast_node.alias] = a
              1
            }
          end
        end

        GraphQL::Schema.define do
          query(query_type)
        end
      }

      let(:query_string) {<<-GRAPHQL
        query testVariables(
          $intWithVariable: Int,
          $intWithDefault: Int = 10,
          $intDefaultNull: Int = null,
          $intWithoutVariable: Int,
        ) {
          a: variables_test(val: $intWithVariable)
          b: variables_test(val: $intWithDefault)
          c: variables_test(val: $intDefaultNull)
          d: variables_test(val: $intWithoutVariable)
        }
      GRAPHQL
      }

      let(:variables) { GraphQL::Query::Variables.new(
        schema,
        GraphQL::Schema::Warden.new(schema.default_mask, schema: schema, context: nil),
        ast_variables,
        provided_variables)
      }

      it "preserves explicit null" do
        assert_equal nil, variables["intWithVariable"]
        assert_equal true, variables.key?("intWithVariable")
      end

      it "doesn't contain variables that weren't present" do
        assert_equal nil, variables["intWithoutVariable"]
        assert_equal false, variables.key?("intWithoutVariable")
      end

      it "preserves explicit null when variable has a default value" do
        assert_equal nil, variables["intWithDefault"]
        assert_equal true, variables.key?("intWithDefault")
      end

      it "uses null default value" do
        assert_equal nil, variables["intDefaultNull"]
        assert_equal true, variables.key?("intDefaultNull")
      end
    end
  end
end
