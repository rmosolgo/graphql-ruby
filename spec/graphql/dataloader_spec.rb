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

    class Loader
      def initialize(context)
        @context = context
        @ids = []
        @data = {}
      end

      def self.for(context)
        context[:loader] ||= self.new(context)
      end

      def load(id_or_ids)
        puts "[Fiber:#{Fiber.current.object_id}] loading #{id_or_ids}"
        if id_or_ids.is_a?(Array)
          _local_ids, pending_ids = id_or_ids.partition { |id| @data.key?(id) }
          if pending_ids.any?
            @ids.concat(pending_ids)
            @context.yield_graphql
            _local_ids, pending_ids = id_or_ids.partition { |id| @data.key?(id) }
            if pending_ids.any?
              sync
            end
          end
          id_or_ids.map { |id| @data[id] }
        else
          @data[id_or_ids] || begin
            @ids.push(id_or_ids)
            @context.yield_graphql
            if !@data.key?(id_or_ids)
              sync
            end
            @data[id_or_ids]
          end
        end
      end

      def sync
        if @ids.any?
          puts "[Fiber:#{Fiber.current.object_id}] sync #{@ids}"
          records = Database.mget(@ids)
          @ids.each_with_index do |id, idx|
            @data[id] = records[idx]
          end
          @ids = []
        end
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
        ingredients = Loader.for(context).load(object[:ingredient_ids])
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
    context = {}
    res = FiberSchema.execute <<-GRAPHQL, context: context
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
    expected_log = [
      [:mget, [
        "1", "2",           # The first 2 ingredients
        "5",                # The first recipe
        "6"]                # recipeIngredient recipeId
      ],
      [:mget, [
        "3", "4",            # The two unfetched ingredients the first recipe
        "7" ]                # recipeIngredient ingredient_id
      ],
    ]
    assert_equal expected_log, database_log
    assert_nil context[:ids]
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
  end
end
