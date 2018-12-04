# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Execution::Interpreter do
  module InterpreterTest
    class Box
      attr_reader :value

      def initialize(value:)
        @value = value
      end
    end

    class Expansion < GraphQL::Schema::Object
      field :sym, String, null: false
      field :lazy_sym, String, null: false
      field :name, String, null: false
      field :cards, ["InterpreterTest::Card"], null: false

      def self.authorized?(expansion, ctx)
        if expansion.sym == "NOPE"
          false
        else
          true
        end
      end

      def cards
        Query::CARDS.select { |c| c.expansion_sym == @object.sym }
      end

      def lazy_sym
        Box.new(value: sym)
      end
    end

    class Card < GraphQL::Schema::Object
      field :name, String, null: false
      field :colors, "[InterpreterTest::Color]", null: false
      field :expansion, Expansion, null: false

      def expansion
        Query::EXPANSIONS.find { |e| e.sym == @object.expansion_sym }
      end
    end

    class Color < GraphQL::Schema::Enum
      value "WHITE"
      value "BLUE"
      value "BLACK"
      value "RED"
      value "GREEN"
    end

    class Entity < GraphQL::Schema::Union
      possible_types Card, Expansion

      def self.resolve_type(obj, ctx)
        obj.sym ? Expansion : Card
      end
    end

    class FieldCounter < GraphQL::Schema::Object
      field :field_counter, FieldCounter, null: false
      def field_counter; :field_counter; end

      field :calls, Integer, null: false do
        argument :expected, Integer, required: true
      end
      def calls(expected:)
        c = context[:calls] += 1
        if c != expected
          raise "Expected #{expected} calls but had #{c} so far"
        else
          c
        end
      end
    end

    class Query < GraphQL::Schema::Object
      # Try a root-level authorized hook that returns a lazy value
      def self.authorized?(obj, ctx)
        Box.new(value: true)
      end

      field :card, Card, null: true do
        argument :name, String, required: true
      end

      def card(name:)
        Box.new(value: CARDS.find { |c| c.name == name })
      end

      field :expansion, Expansion, null: true do
        argument :sym, String, required: true
      end

      def expansion(sym:)
        EXPANSIONS.find { |e| e.sym == sym }
      end

      field :expansions, [Expansion], null: false
      def expansions
        EXPANSIONS
      end

      CARDS = [
        OpenStruct.new(name: "Dark Confidant", colors: ["BLACK"], expansion_sym: "RAV"),
      ]

      EXPANSIONS = [
        OpenStruct.new(name: "Ravnica, City of Guilds", sym: "RAV"),
        # This data has an error, for testing null propagation
        OpenStruct.new(name: nil, sym: "XYZ"),
        # This is not allowed by .authorized?,
        OpenStruct.new(name: nil, sym: "NOPE"),
      ]

      field :find, [Entity], null: false do
        argument :id, [ID], required: true
      end

      def find(id:)
        id.map do |ent_id|
          Query::EXPANSIONS.find { |e| e.sym == ent_id } ||
            Query::CARDS.find { |c| c.name == ent_id }
        end
      end

      field :field_counter, FieldCounter, null: false
      def field_counter; :field_counter; end
    end

    class Schema < GraphQL::Schema
      use GraphQL::Execution::Interpreter
      query(Query)
      lazy_resolve(Box, :value)
    end
  end

  it "runs a query" do
    query_string = <<-GRAPHQL
    query($expansion: String!, $id1: ID!, $id2: ID!){
      card(name: "Dark Confidant") {
        colors
        expansion {
          ... {
            name
          }
          cards {
            name
          }
        }
      }
      expansion(sym: $expansion) {
        ... ExpansionFields
      }
      find(id: [$id1, $id2]) {
        __typename
        ... on Card {
          name
        }
        ... on Expansion {
          sym
        }
      }
    }

    fragment ExpansionFields on Expansion {
      cards {
        name
      }
    }
    GRAPHQL

    vars = {expansion: "RAV", id1: "Dark Confidant", id2: "RAV"}
    result = InterpreterTest::Schema.execute(query_string, variables: vars)
    assert_equal ["BLACK"], result["data"]["card"]["colors"]
    assert_equal "Ravnica, City of Guilds", result["data"]["card"]["expansion"]["name"]
    assert_equal [{"name" => "Dark Confidant"}], result["data"]["card"]["expansion"]["cards"]
    assert_equal [{"name" => "Dark Confidant"}], result["data"]["expansion"]["cards"]
    expected_abstract_list = [
      {"__typename" => "Card", "name" => "Dark Confidant"},
      {"__typename" => "Expansion", "sym" => "RAV"},
    ]
    assert_equal expected_abstract_list, result["data"]["find"]
  end

  it "runs skip and include" do
    query_str = <<-GRAPHQL
    query($truthy: Boolean!, $falsey: Boolean!){
      exp1: expansion(sym: "RAV") @skip(if: true) { name }
      exp2: expansion(sym: "RAV") @skip(if: false) { name }
      exp3: expansion(sym: "RAV") @include(if: true) { name }
      exp4: expansion(sym: "RAV") @include(if: false) { name }
      exp5: expansion(sym: "RAV") @include(if: $truthy) { name }
      exp6: expansion(sym: "RAV") @include(if: $falsey) { name }
    }
    GRAPHQL

    vars = {truthy: true, falsey: false}
    result = InterpreterTest::Schema.execute(query_str, variables: vars)
    expected_data = {
      "exp2" => {"name" => "Ravnica, City of Guilds"},
      "exp3" => {"name" => "Ravnica, City of Guilds"},
      "exp5" => {"name" => "Ravnica, City of Guilds"},
    }
    assert_equal expected_data, result["data"]
  end

  describe "temporary interpreter flag" do
    it "is set" do
      # This can be removed later, just a sanity check during migration
      res = InterpreterTest::Schema.execute("{ __typename }")
      assert_equal true, res.context.interpreter?
    end
  end

  describe "CI setup" do
    it "sets interpreter based on a constant" do
      if TESTING_INTERPRETER
        assert_equal GraphQL::Execution::Interpreter, Jazz::Schema.query_execution_strategy
        assert_equal GraphQL::Execution::Interpreter, Dummy::Schema.query_execution_strategy
      else
        refute_equal GraphQL::Execution::Interpreter, Jazz::Schema.query_execution_strategy
        refute_equal GraphQL::Execution::Interpreter, Dummy::Schema.query_execution_strategy
      end
    end
  end
  describe "null propagation" do
    it "propagates nulls" do
      query_str = <<-GRAPHQL
      {
        expansion(sym: "XYZ") {
          name
          sym
          lazySym
        }
      }
      GRAPHQL

      res = InterpreterTest::Schema.execute(query_str)
      # Although the expansion was found, its name of `nil`
      # propagated to here
      assert_nil res["data"].fetch("expansion")
      assert_equal ["Cannot return null for non-nullable field Expansion.name"], res["errors"].map { |e| e["message"] }
    end

    it "propagates nulls in lists" do
      query_str = <<-GRAPHQL
      {
        expansions {
          name
          sym
          lazySym
        }
      }
      GRAPHQL

      res = InterpreterTest::Schema.execute(query_str)
      # A null in one of the list items removed the whole list
      assert_nil(res["data"])
    end

    it "works with unions that fail .authorized?" do
      res = InterpreterTest::Schema.execute <<-GRAPHQL
      {
        find(id: "NOPE") {
          ... on Expansion {
            sym
          }
        }
      }
      GRAPHQL
      assert_equal ["Cannot return null for non-nullable field Query.find"], res["errors"].map { |e| e["message"] }
    end
  end

  describe "duplicated fields" do
    it "doesn't run them multiple times" do
      query_str = <<-GRAPHQL
      {
        fieldCounter {
          calls(expected: 1)
          # This should not be called since it matches the above
          calls(expected: 1)
          fieldCounter {
            calls(expected: 2)
          }
          ...ExtraFields
        }
      }
      fragment ExtraFields on FieldCounter {
        fieldCounter {
          # This should not be called since it matches the inline field:
          calls(expected: 2)
          # This _should_ be called
          c3: calls(expected: 3)
        }
      }
      GRAPHQL

      # It will raise an error if it doesn't match the expectation
      res = InterpreterTest::Schema.execute(query_str, context: { calls: 0 })
      assert_equal 3, res["data"]["fieldCounter"]["fieldCounter"]["c3"]
    end
  end
end
