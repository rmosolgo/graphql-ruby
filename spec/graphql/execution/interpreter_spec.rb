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
      field :name, String, null: false
      field :cards, ["InterpreterTest::Card"], null: false

      def cards
        Query::CARDS.select { |c| c.expansion_sym == @object.sym }
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

    class Query < GraphQL::Schema::Object
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

      CARDS = [
        OpenStruct.new(name: "Dark Confidant", colors: ["BLACK"], expansion_sym: "RAV"),
      ]

      EXPANSIONS = [
        OpenStruct.new(name: "Ravnica, City of Guilds", sym: "RAV"),
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
    end

    class Schema < GraphQL::Schema
      query(Query)
      lazy_resolve(Box, :value)
    end

    # TODO encapsulate this in `use` ?
    Schema.graphql_definition.query_execution_strategy = GraphQL::Execution::Interpreter
    # Don't want this wrapping automatically
    Schema.instrumenters[:field].delete(GraphQL::Schema::Member::Instrumentation)
    Schema.instrumenters[:query].delete(GraphQL::Schema::Member::Instrumentation)
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
end
