# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Execution::Interpreter do
  module InterpreterTest
    class Box
      def initialize(value: nil, &block)
        @value = value
        @block = block
      end

      def value
        if @block
          @value = @block.call
          @block = nil
        end
        @value
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
        Box.new(value: object.sym)
      end

      field :null_union_field_test, Integer, null: false
      def null_union_field_test
        1
      end

      field :always_cached_value, Integer, null: false
      def always_cached_value
        raise "should never be called"
      end
    end

    class Card < GraphQL::Schema::Object
      field :name, String, null: false
      field :colors, "[InterpreterTest::Color]", null: false
      field :expansion, Expansion, null: false

      def expansion
        Query::EXPANSIONS.find { |e| e.sym == @object.expansion_sym }
      end

      field :null_union_field_test, Integer, null: true
      def null_union_field_test
        nil
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
      implements GraphQL::Types::Relay::Node

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

      field :runtime_info, String, null: false
      def runtime_info
        "#{context.namespace(:interpreter)[:current_path]} -> #{context.namespace(:interpreter)[:current_field].path}"
      end

      field :lazy_runtime_info, String, null: false
      def lazy_runtime_info
        Box.new {
          "#{context.namespace(:interpreter)[:current_path]} -> #{context.namespace(:interpreter)[:current_field].path}"
        }
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

      field :expansion_raw, Expansion, null: false

      def expansion_raw
        raw_value(sym: "RAW", name: "Raw expansion", always_cached_value: 42)
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

      field :find_many, [Entity, null: true], null: false do
        argument :ids, [ID], required: true
      end

      def find_many(ids:)
        find(id: ids).map { |e| Box.new(value: e) }
      end

      field :field_counter, FieldCounter, null: false
      def field_counter; :field_counter; end

      field :node, field: GraphQL::Relay::Node.field
      field :nodes, field: GraphQL::Relay::Node.plural_field
    end

    class Counter < GraphQL::Schema::Object
      field :value, Integer, null: false
      field :lazy_value, Integer, null: false

      def lazy_value
        Box.new { object.value }
      end

      field :increment, Counter, null: false

      def increment
        object.value += 1
        object
      end
    end


    class Mutation < GraphQL::Schema::Object
      field :increment_counter, Counter, null: false

      def increment_counter
        counter = context[:counter]
        counter.value += 1
        counter
      end
    end

    class Schema < GraphQL::Schema
      use GraphQL::Execution::Interpreter
      use GraphQL::Analysis::AST
      query(Query)
      mutation(Mutation)
      lazy_resolve(Box, :value)

      def self.object_from_id(id, ctx)
        OpenStruct.new(id: id)
      end

      def self.resolve_type(type, obj, ctx)
        FieldCounter
      end
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

  it "runs mutation roots atomically and sequentially" do
    query_str = <<-GRAPHQL
    mutation {
      i1: incrementCounter { value lazyValue
        i2: increment { value lazyValue }
        i3: increment { value lazyValue }
      }
      i4: incrementCounter { value lazyValue }
      i5: incrementCounter { value lazyValue }
    }
    GRAPHQL

    result = InterpreterTest::Schema.execute(query_str, context: { counter: OpenStruct.new(value: 0) })
    expected_data = {
      "i1" => {
        "value" => 1,
        # All of these get `3` as lazy value. They're resolved together,
        # since they aren't _root_ mutation fields.
        "lazyValue" => 3,
        "i2" => { "value" => 2, "lazyValue" => 3 },
        "i3" => { "value" => 3, "lazyValue" => 3 },
      },
      "i4" => { "value" => 4, "lazyValue" => 4},
      "i5" => { "value" => 5, "lazyValue" => 5},
    }
    assert_equal expected_data, result["data"]
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

  describe "runtime info in context" do
    it "is available" do
      res = InterpreterTest::Schema.execute <<-GRAPHQL
      {
        fieldCounter {
          runtimeInfo
          fieldCounter {
            runtimeInfo
            lazyRuntimeInfo
          }
        }
      }
      GRAPHQL

      assert_equal '["fieldCounter", "runtimeInfo"] -> FieldCounter.runtimeInfo', res["data"]["fieldCounter"]["runtimeInfo"]
      assert_equal '["fieldCounter", "fieldCounter", "runtimeInfo"] -> FieldCounter.runtimeInfo', res["data"]["fieldCounter"]["fieldCounter"]["runtimeInfo"]
      assert_equal '["fieldCounter", "fieldCounter", "lazyRuntimeInfo"] -> FieldCounter.lazyRuntimeInfo', res["data"]["fieldCounter"]["fieldCounter"]["lazyRuntimeInfo"]
    end
  end

  describe "CI setup" do
    it "sets interpreter based on a constant" do
      # Force the plugins to be applied
      Jazz::Schema.graphql_definition
      Dummy::Schema.graphql_definition
      if TESTING_INTERPRETER
        assert_equal GraphQL::Execution::Interpreter, Jazz::Schema.query_execution_strategy
      else
        refute_equal GraphQL::Execution::Interpreter, Jazz::Schema.query_execution_strategy
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

    it "works with lists of unions" do
      res = InterpreterTest::Schema.execute <<-GRAPHQL
      {
        findMany(ids: ["RAV", "NOPE", "BOGUS"]) {
          ... on Expansion {
            sym
          }
        }
      }
      GRAPHQL

      assert_equal 3, res["data"]["findMany"].size
      assert_equal "RAV", res["data"]["findMany"][0]["sym"]
      assert_equal nil, res["data"]["findMany"][1]
      assert_equal nil, res["data"]["findMany"][2]
      assert_equal false, res.key?("errors")
    end

    it "works with union lists that have members of different kinds, with different nullabilities" do
      res = InterpreterTest::Schema.execute <<-GRAPHQL
      {
        findMany(ids: ["RAV", "Dark Confidant"]) {
          ... on Expansion {
            nullUnionFieldTest
          }
          ... on Card {
            nullUnionFieldTest
          }
        }
      }
      GRAPHQL

      assert_equal [1, nil], res["data"]["findMany"].map { |f| f["nullUnionFieldTest"] }
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

  describe "backwards compatibility" do
    it "handles a legacy nodes field" do
      res = InterpreterTest::Schema.execute('{ node(id: "abc") { id } }')
      assert_equal "abc", res["data"]["node"]["id"]

      res = InterpreterTest::Schema.execute('{ nodes(ids: ["abc", "xyz"]) { id } }')
      assert_equal ["abc", "xyz"], res["data"]["nodes"].map { |n| n["id"] }
    end
  end

  describe "returning raw values" do
    it "returns raw value" do
      query_str = <<-GRAPHQL
      {
        expansionRaw {
          name
          sym
          alwaysCachedValue
        }
      }
      GRAPHQL

      res = InterpreterTest::Schema.execute(query_str)
      assert_equal({ sym: "RAW", name: "Raw expansion", always_cached_value: 42 }, res["data"]["expansionRaw"])
    end
  end
end
