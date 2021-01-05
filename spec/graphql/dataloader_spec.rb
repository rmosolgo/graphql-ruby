# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Dataloader do
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

      def find_by(attribute, keys)
        log << [:find_by, attribute, keys]
        keys.map { |k| DATA.each_value.find { |v| v[attribute] == k } }
      end
    end

    class Loader < GraphQL::Dataloader::Source
      def initialize(dataloader, column = :id)
        @column = column
        super(dataloader)
      end

      def fetch(keys)
        if @column == :id
          Database.mget(keys)
        else
          Database.find_by(@column, keys)
        end
      end
    end

    class NestedLoader < GraphQL::Dataloader::Source
      def fetch(ids)
        @dataloader.with(Loader).load_all(ids)
      end
    end

    module Ingredient
      include GraphQL::Schema::Interface
      field :name, String, null: false
      field :id, ID, null: false
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
        ingredients = dataloader.with(Loader).load_all(object[:ingredient_ids])
        ingredients
      end
    end

    class Query < GraphQL::Schema::Object
      field :ingredient, Ingredient, null: true do
        argument :id, ID, required: true
      end

      def ingredient(id:)
        dataloader.with(Loader).load(id)
      end

      field :ingredient_by_name, Ingredient, null: true do
        argument :name, String, required: true
      end

      def ingredient_by_name(name:)
        dataloader.with(Loader, :name).load(name)
      end

      field :nested_ingredient, Ingredient, null: true do
        argument :id, ID, required: true
      end

      def nested_ingredient(id:)
        dataloader.with(NestedLoader).load(id)
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
        recipe = dataloader.with(Loader).load(recipe_id)
        ingredient_id = recipe[:ingredient_ids][ingredient_number - 1]
        dataloader.with(Loader).load(ingredient_id)
      end

      field :common_ingredients, [Ingredient], null: true do
        argument :recipe_1_id, ID, required: true
        argument :recipe_2_id, ID, required: true
      end

      def common_ingredients(recipe_1_id:, recipe_2_id:)
        req1 = dataloader.with(Loader).request(recipe_1_id)
        req2 = dataloader.with(Loader).request(recipe_2_id)
        recipe1 = req1.load
        recipe2 = req2.load
        common_ids = recipe1[:ingredient_ids] & recipe2[:ingredient_ids]
        dataloader.with(Loader).load_all(common_ids)
      end
    end

    query(Query)

    def self.object_from_id(id, ctx)
      ctx.dataloader.with(Loader).load(id)
    end

    def self.resolve_type(type, obj, ctx)
      get_type(obj[:type])
    end

    orphan_types(Grain, Dairy, Recipe, LeaveningAgent)
    use GraphQL::Analysis::AST
    use GraphQL::Execution::Interpreter
    use GraphQL::Dataloader
  end

  def database_log
    FiberSchema::Database.log
  end

  before do
    database_log.clear
  end

  it "Works with request(...)" do
    res = FiberSchema.execute <<-GRAPHQL
    {
      commonIngredients(recipe1Id: 5, recipe2Id: 6) {
        name
      }
    }
    GRAPHQL

    expected_data = {
      "data" => {
        "commonIngredients" => [
          { "name" => "Corn" },
          { "name" => "Butter" },
        ]
      }
    }
    assert_equal expected_data, res
    assert_equal [[:mget, ["5", "6"]], [:mget, ["2", "3"]]], database_log
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
    context = {}
    result = FiberSchema.multiplex([
      { query: "{ i1: ingredient(id: 1) { name } i2: ingredient(id: 2) { name } }", },
      { query: "{ i2: ingredient(id: 2) { name } r1: recipe(id: 5) { ingredients { name } } }", },
      { query: "{ i1: ingredient(id: 1) { name } ri1: recipeIngredient(recipeId: 5, ingredientNumber: 2) { name } }", },
    ], context: context)

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
    assert_equal 0, context[:dataloader].yielded_fibers.size, "All yielded fibers are cleaned up when they're finished"
  end

  it "works with calls within sources" do
    res = FiberSchema.execute <<-GRAPHQL
    {
      i1: nestedIngredient(id: 1) { name }
      i2: nestedIngredient(id: 2) { name }
    }
    GRAPHQL

    expected_data = { "i1" => { "name" => "Wheat" }, "i2" => { "name" => "Corn" } }
    assert_equal expected_data, res["data"]
    assert_equal [[:mget, ["1", "2"]]], database_log
  end

  it "works with batch parameters" do
    res = FiberSchema.execute <<-GRAPHQL
    {
      i1: ingredientByName(name: "Butter") { id }
      i2: ingredientByName(name: "Corn") { id }
      i3: ingredientByName(name: "Gummi Bears") { id }
    }
    GRAPHQL

    expected_data = {
      "i1" => { "id" => "3" },
      "i2" => { "id" => "2" },
      "i3" => nil,
    }
    assert_equal expected_data, res["data"]
    assert_equal [[:find_by, :name, ["Butter", "Corn", "Gummi Bears"]]], database_log
  end
end
