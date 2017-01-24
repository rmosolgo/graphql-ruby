# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::VariableDefaultValuesAreCorrectlyTyped do
  include StaticValidationHelpers

  let(:query_string) {%|
    query getCheese(
      $id:        Int = 1,
      $int:       Int = 3.4e24, # can be coerced
      $str:       String!,
      $badInt:    Int = "abc",
      $input:     DairyProductInput = {source: YAK, fatContent: 1},
      $badInput:  DairyProductInput = {source: YAK, fatContent: true},
      $nonNull:  Int! = 1,
    ) {
      cheese1: cheese(id: $id) { source }
      cheese4: cheese(id: $int) { source }
      cheese2: cheese(id: $badInt) { source }
      cheese3: cheese(id: $nonNull) { source }
      search1: searchDairy(product: [$input]) { __typename }
      search2: searchDairy(product: [$badInput]) { __typename }
      __type(name: $str) { name }
    }
  |}

  it "finds default values that don't match their types" do
    expected = [
      {
        "message"=>"Default value for $badInt doesn't match type Int",
        "locations"=>[{"line"=>6, "column"=>7}],
        "fields"=>["query getCheese", "$badInt"],
      },
      {
        "message"=>"Default value for $badInput doesn't match type DairyProductInput",
        "locations"=>[{"line"=>8, "column"=>7}],
        "fields"=>["query getCheese", "$badInput"],
      },
      {
        "message"=>"Non-null variable $nonNull can't have a default value",
        "locations"=>[{"line"=>9, "column"=>7}],
        "fields"=>["query getCheese", "$nonNull"],
      }
    ]
    assert_equal(expected, errors)
  end

  describe "null default values" do
    describe "variables with valid default null values" do
      let(:schema) {
        GraphQL::Schema.from_definition(%|
          type Query {
            field(a: Int, b: String, c: ComplexInput): Int
          }

          input ComplexInput {
            requiredField: Boolean!
            intField: Int
          }
        |)
      }

      let(:query_string) {%|
        query getCheese(
          $a: Int = null,
          $b: String = null,
          $c: ComplexInput = { requiredField: true, intField: null }
        ) {
          field(a: $a, b: $b, c: $c)
        }
      |}

      it "finds no errors" do
        assert_equal [], errors
      end
    end

    describe "variables with invalid default null values" do
      let(:schema) {
        GraphQL::Schema.from_definition(%|
          type Query {
            field(a: Int!, b: String!, c: ComplexInput): Int
          }

          input ComplexInput {
            requiredField: Boolean!
            intField: Int
          }
        |)
      }

      let(:query_string) {%|
        query getCheese(
          $a: Int! = null,
          $b: String! = null,
          $c: ComplexInput = { requiredField: null, intField: null }
        ) {
          field(a: $a, b: $b, c: $c)
        }
      |}

      it "finds errors" do
        expected = [
          {
            "message"=>"Non-null variable $a can't have a default value",
            "locations"=>[{"line"=>3, "column"=>11}],
            "fields"=>["query getCheese", "$a"]
          },
          {
            "message"=>"Non-null variable $b can't have a default value",
            "locations"=>[{"line"=>4, "column"=>11}],
            "fields"=>["query getCheese", "$b"]
          },
          {
            "message"=>"Default value for $c doesn't match type ComplexInput",
            "locations"=>[{"line"=>5, "column"=>11}],
            "fields"=>["query getCheese", "$c"]
          }
        ]

        assert_equal expected, errors
      end
    end
  end
end
