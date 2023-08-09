# frozen_string_literal: true
require 'spec_helper'

describe GraphQL::Schema::HasSingleInputArgument do
  describe ".input_object_class" do
    it "is inherited, with a default" do
      custom_input = Class.new(GraphQL::Schema::InputObject)
      mutation_base_class = Class.new(GraphQL::Schema::Mutation) do
        include GraphQL::Schema::HasSingleInputArgument
        graphql_name "Test"
        input_object_class(custom_input)
      end
      mutation_subclass = Class.new(mutation_base_class)

      assert_equal custom_input, mutation_base_class.input_object_class
      assert_equal custom_input, mutation_subclass.input_object_class
    end
  end

  describe ".input_type" do
    it "has a reference to the mutation" do
      mutation = Class.new(GraphQL::Schema::Mutation) do
        include GraphQL::Schema::HasSingleInputArgument
        graphql_name "Test"
      end
      assert_equal mutation, mutation.input_type.mutation
    end
  end

  describe "input argument" do
    it "sets a description for the input argument" do
      mutation = Class.new(GraphQL::Schema::Mutation) do
        include GraphQL::Schema::HasSingleInputArgument
        graphql_name "SomeMutation"
      end

      field = GraphQL::Schema::Field.new(name: "blah", resolver_class: mutation)
      assert_equal "Parameters for SomeMutation", field.get_argument("input").description
    end
  end

  describe "execution" do
    after do
      Jazz::Models.reset
    end

    it "works with no arguments" do
      res = Jazz::Schema.execute <<-GRAPHQL
      mutation {
        addSitar(input: {}) {
          instrument {
            name
          }
        }
      }
      GRAPHQL
      assert_equal "Sitar", res["data"]["addSitar"]["instrument"]["name"]
    end

    it "works with InputObject arguments" do
      res = Jazz::Schema.execute <<-GRAPHQL
      mutation {
        addEnsembleRelay(input: { ensemble: { name: "Miles Davis Quartet" } }) {
          ensemble {
            name
          }
        }
      }
      GRAPHQL

      assert_equal "Miles Davis Quartet", res["data"]["addEnsembleRelay"]["ensemble"]["name"]
    end

    it "supports extras" do
      res = Jazz::Schema.execute <<-GRAPHQL
      mutation {
        hasExtras(input: {}) {
          nodeClass
          int
        }
      }
      GRAPHQL

      assert_equal "GraphQL::Language::Nodes::Field", res["data"]["hasExtras"]["nodeClass"]
      assert_nil res["data"]["hasExtras"]["int"]

      # Also test with given args
      res = Jazz::Schema.execute <<-GRAPHQL
      mutation {
        hasExtras(input: {int: 5}) {
          nodeClass
          int
        }
      }
      GRAPHQL
      assert_equal "GraphQL::Language::Nodes::Field", res["data"]["hasExtras"]["nodeClass"]
      assert_equal 5, res["data"]["hasExtras"]["int"]
    end

    it "supports field extras" do
      res = Jazz::Schema.execute <<-GRAPHQL
      mutation {
        hasFieldExtras(input: {}) {
          lookaheadClass
          int
        }
      }
      GRAPHQL

      assert_equal "GraphQL::Execution::Lookahead", res["data"]["hasFieldExtras"]["lookaheadClass"]
      assert_nil res["data"]["hasFieldExtras"]["int"]

      # Also test with given args
      res = Jazz::Schema.execute <<-GRAPHQL
      mutation {
        hasFieldExtras(input: {int: 5}) {
          lookaheadClass
          int
        }
      }
      GRAPHQL
      assert_equal "GraphQL::Execution::Lookahead", res["data"]["hasFieldExtras"]["lookaheadClass"]
      assert_equal 5, res["data"]["hasFieldExtras"]["int"]
    end

    it "can strip out extras" do
      ctx = {}
      res = Jazz::Schema.execute <<-GRAPHQL, context: ctx
      mutation {
        hasExtrasStripped(input: {}) {
          int
        }
      }
      GRAPHQL
      assert_equal true, ctx[:has_lookahead]
      assert_equal 51, res["data"]["hasExtrasStripped"]["int"]
    end
  end
end
