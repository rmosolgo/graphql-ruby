# frozen_string_literal: true
require "spec_helper"

describe "fiber data loading" do
  class FiberSchema < GraphQL::Schema
    module Database
      extend self
      DATA = {}
      [
        { id: "1", name: "Wheat", type: "Grain" },
        { id: "2", name: "Corn", type: "Grain" },
        { id: "3", name: "Butter", type: "Dairy" },
        { id: "4", name: "Baking Soda", type: "LeaveningAgent" },
        { id: "5", name: "Cornbread", type: "Recipe", ingredient_ids: ["1", "2", "3", "4"] },
        { id: "6", name: "Grits", type: "Recipe", ingredient_ids: ["2", "3", "7"] },
        { id: "7", name: "Cheese", type: "Dairy" },
      ].each { |d| DATA[d[:id]] = d }

      def log
        @log ||= []
      end

      def mget(ids)
        log << [:mget, ids]
        ids.map { |id| DATA[id] }
      end
    end

    class Loader < GraphQL::Dataloader::Source
      # TODO a system of managing these
      def self.for(context)
        context.query.multiplex.context[:loader] ||= self.new(context)
      end

      def fetch(ids)
        # puts "[Fiber:#{Fiber.current.object_id}] fetch #{ids}"
        Database.mget(ids)
      end
    end

    module Ingredient
      include GraphQL::Schema::Interface
      field :name, String, null: false
    end

    class Grain < GraphQL::Schema::Object
      implements Ingredient
    end

    class LeaveningAgent < GraphQL::Schema::Object
      implements Ingredient
    end

    class Dairy < GraphQL::Schema::Object
      implements Ingredient
    end

    class Recipe < GraphQL::Schema::Object
      field :name, String, null: false
      field :ingredients, [Ingredient], null: false

      def ingredients
        ingredients = Loader.for(context).load_all(object[:ingredient_ids])
        ingredients
      end
    end

    class Query < GraphQL::Schema::Object
      field :ingredient, Ingredient, null: true, resolver_method: :item do
        argument :id, ID, required: true
      end

      def item(id:)
        Loader.for(context).load(id)
      end

      field :recipe, Recipe, null: true do
        argument :id, ID, required: true, loads: Recipe, as: :recipe
      end

      def recipe(recipe:)
        recipe
      end

      field :recipe_ingredient, Ingredient, null: true do
        argument :recipe_id, ID, required: true
        argument :ingredient_number, Int, required: true
      end

      def recipe_ingredient(recipe_id:, ingredient_number:)
        recipe = Loader.for(context).load(recipe_id)
        ingredient_id = recipe[:ingredient_ids][ingredient_number - 1]
        Loader.for(context).load(ingredient_id)
      end
    end

    query(Query)

    def self.object_from_id(id, ctx)
      Loader.for(ctx).load(id)
    end

    def self.resolve_type(type, obj, ctx)
      get_type(obj[:type])
    end

    orphan_types(Grain, Dairy, Recipe, LeaveningAgent)
    use GraphQL::Analysis::AST
    use GraphQL::Execution::Interpreter
  end

  def database_log
    FiberSchema::Database.log
  end

  before do
    database_log.clear
  end

  it "batch-loads" do
    res = FiberSchema.execute <<-GRAPHQL
    {
      i1: ingredient(id: 1) { name }
      i2: ingredient(id: 2) { name }
      r1: recipe(id: 5) {
        ingredients { name }
      }
      ri1: recipeIngredient(recipeId: 6, ingredientNumber: 3) {
        name
      }
    }
    GRAPHQL

    expected_data = {
      "i1" => { "name" => "Wheat" },
      "i2" => { "name" => "Corn" },
      "r1" => {
        "ingredients" => [
          { "name" => "Wheat" },
          { "name" => "Corn" },
          { "name" => "Butter" },
          { "name" => "Baking Soda" },
        ],
      },
      "ri1" => {
        "name" => "Cheese",
      },
    }
    assert_equal(expected_data, res["data"])

    expected_log = [
      [:mget, [
        "1", "2",           # The first 2 ingredients
        "5",                # The first recipe
        "6",                # recipeIngredient recipeId
      ]],
      [:mget, [
        "7",                # recipeIngredient ingredient_id
        "3", "4",           # The two unfetched ingredients the first recipe
      ]],
    ]
    assert_equal expected_log, database_log
  end

  it "caches and batch-loads across a multiplex" do
    result = FiberSchema.multiplex([
      { query: "{ i1: ingredient(id: 1) { name } i2: ingredient(id: 2) { name } }", },
      { query: "{ i2: ingredient(id: 2) { name } r1: recipe(id: 5) { ingredients { name } } }", },
      { query: "{ i1: ingredient(id: 1) { name } ri1: recipeIngredient(recipeId: 5, ingredientNumber: 2) { name } }", },
    ])

    expected_result = [
      {"data"=>{"i1"=>{"name"=>"Wheat"}, "i2"=>{"name"=>"Corn"}}},
      {"data"=>{"i2"=>{"name"=>"Corn"}, "r1"=>{"ingredients"=>[{"name"=>"Wheat"}, {"name"=>"Corn"}, {"name"=>"Butter"}, {"name"=>"Baking Soda"}]}}},
      {"data"=>{"i1"=>{"name"=>"Wheat"}, "ri1"=>{"name"=>"Corn"}}},
    ]
    assert_equal expected_result, result
    expected_log = [
      [:mget, ["1", "5", "2"]],
      [:mget, ["3", "4"]],
    ]
    assert_equal expected_log, database_log
  end
end
