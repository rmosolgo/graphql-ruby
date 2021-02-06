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
        log << [:mget, ids.sort]
        ids.map { |id| DATA[id] }
      end

      def find_by(attribute, values)
        log << [:find_by, attribute, values.sort]
        values.map { |v| DATA.each_value.find { |dv| dv[attribute] == v } }
      end
    end

    class DataObject < GraphQL::Dataloader::Source
      def initialize(column = :id)
        @column = column
      end

      def fetch(keys)
        if @column == :id
          Database.mget(keys)
        else
          Database.find_by(@column, keys)
        end
      end
    end

    class NestedDataObject < GraphQL::Dataloader::Source
      def fetch(ids)
        @dataloader.with(DataObject).load_all(ids)
      end
    end

    class SlowDataObject < GraphQL::Dataloader::Source
      def initialize(batch_key)
        # This is just so that I can force different instances in test
        @batch_key = batch_key
      end

      def fetch(keys)
        t = Thread.new {
          sleep 0.5
          Database.mget(keys)
        }
        dataloader.yield
        t.value
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
        ingredients = dataloader.with(DataObject).load_all(object[:ingredient_ids])
        ingredients
      end

      field :slow_ingredients, [Ingredient], null: false

      def slow_ingredients
        # Use `object[:id]` here to force two different instances of the loader in the test
        dataloader.with(SlowDataObject, object[:id]).load_all(object[:ingredient_ids])
      end
    end

    class Query < GraphQL::Schema::Object
      field :recipes, [Recipe], null: false

      def recipes
        Database.mget(["5", "6"])
      end

      field :ingredient, Ingredient, null: true do
        argument :id, ID, required: true
      end

      def ingredient(id:)
        dataloader.with(DataObject).load(id)
      end

      field :ingredient_by_name, Ingredient, null: true do
        argument :name, String, required: true
      end

      def ingredient_by_name(name:)
        dataloader.with(DataObject, :name).load(name)
      end

      field :nested_ingredient, Ingredient, null: true do
        argument :id, ID, required: true
      end

      def nested_ingredient(id:)
        dataloader.with(NestedDataObject).load(id)
      end

      field :slow_recipe, Recipe, null: true do
        argument :id, ID, required: true
      end

      def slow_recipe(id:)
        dataloader.with(SlowDataObject, id).load(id)
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
        recipe = dataloader.with(DataObject).load(recipe_id)
        ingredient_id = recipe[:ingredient_ids][ingredient_number - 1]
        dataloader.with(DataObject).load(ingredient_id)
      end

      field :common_ingredients, [Ingredient], null: true do
        argument :recipe_1_id, ID, required: true
        argument :recipe_2_id, ID, required: true
      end

      def common_ingredients(recipe_1_id:, recipe_2_id:)
        req1 = dataloader.with(DataObject).request(recipe_1_id)
        req2 = dataloader.with(DataObject).request(recipe_2_id)
        recipe1 = req1.load
        recipe2 = req2.load
        common_ids = recipe1[:ingredient_ids] & recipe2[:ingredient_ids]
        dataloader.with(DataObject).load_all(common_ids)
      end

      field :common_ingredients_with_load, [Ingredient], null: false do
        argument :recipe_1_id, ID, required: true, loads: Recipe
        argument :recipe_2_id, ID, required: true, loads: Recipe
      end

      def common_ingredients_with_load(recipe_1:, recipe_2:)
        common_ids = recipe_1[:ingredient_ids] & recipe_2[:ingredient_ids]
        dataloader.with(DataObject).load_all(common_ids)
      end

      field :common_ingredients_from_input_object, [Ingredient], null: false do
        class CommonIngredientsInput < GraphQL::Schema::InputObject
          argument :recipe_1_id, ID, required: true, loads: Recipe
          argument :recipe_2_id, ID, required: true, loads: Recipe
        end
        argument :input, CommonIngredientsInput, required: true
      end


      def common_ingredients_from_input_object(input:)
        recipe_1 = input[:recipe_1]
        recipe_2 = input[:recipe_2]
        common_ids = recipe_1[:ingredient_ids] & recipe_2[:ingredient_ids]
        dataloader.with(DataObject).load_all(common_ids)
      end
    end

    query(Query)

    def self.object_from_id(id, ctx)
      if ctx[:use_request]
        ctx.dataloader.with(DataObject).request(id)
      else
        ctx.dataloader.with(DataObject).load(id)
      end
    end

    def self.resolve_type(type, obj, ctx)
      get_type(obj[:type])
    end

    orphan_types(Grain, Dairy, Recipe, LeaveningAgent)
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
      i1: ingredient(id: 1) { id name }
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
      "i1" => { "id" => "1", "name" => "Wheat" },
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
        "3", "4",           # The two unfetched ingredients the first recipe
        "7",                # recipeIngredient ingredient_id
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
      [:mget, ["1", "2", "5"]],
      [:mget, ["3", "4"]],
    ]
    assert_equal expected_log, database_log
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

  it "works with manual parallelism" do
    start = Time.now.to_f
    FiberSchema.execute <<-GRAPHQL
    {
      i1: slowRecipe(id: 5) { slowIngredients { name } }
      i2: slowRecipe(id: 6) { slowIngredients { name } }
    }
    GRAPHQL
    finish = Time.now.to_f

    # Each load slept for 0.5 second, so sequentially, this would have been 2s sequentially
    assert_in_delta 1, finish - start, 0.1, "Load threads are executed in parallel"
    expected_log = [
      # These were separated because of different recipe IDs:
      [:mget, ["5"]],
      [:mget, ["6"]],
      # These were cached separately because of different recipe IDs:
      [:mget, ["2", "3", "7"]],
      [:mget, ["1", "2", "3", "4"]],
    ]
    # Sort them because threads may have returned in slightly different order
    assert_equal expected_log.sort, database_log.sort
  end

  it "Works with multiple-field selections and __typename" do
    query_str = <<-GRAPHQL
    {
      ingredient(id: 1) {
        __typename
        name
      }
    }
    GRAPHQL

    res = FiberSchema.execute(query_str)
    expected_data = {
      "ingredient" => {
        "__typename" => "Grain",
        "name" => "Wheat",
      }
    }
    assert_equal expected_data, res["data"]
  end

  it "Works when the parent field didn't yield" do
    query_str = <<-GRAPHQL
    {
      recipes {
        ingredients {
          name
        }
      }
    }
    GRAPHQL

    res = FiberSchema.execute(query_str)
    expected_data = {
      "recipes" =>[
        { "ingredients" => [
          {"name"=>"Wheat"},
          {"name"=>"Corn"},
          {"name"=>"Butter"},
          {"name"=>"Baking Soda"}
        ]},
        { "ingredients" => [
          {"name"=>"Corn"},
          {"name"=>"Butter"},
          {"name"=>"Cheese"}
        ]},
      ]
    }
    assert_equal expected_data, res["data"]

    expected_log = [
      [:mget, ["5", "6"]],
      [:mget, ["1", "2", "3", "4", "7"]],
    ]
    assert_equal expected_log, database_log
  end

  it "loads arguments in batches, even with request" do
    query_str = <<-GRAPHQL
    {
      commonIngredientsWithLoad(recipe1Id: 5, recipe2Id: 6) {
        name
      }
    }
    GRAPHQL

    res = FiberSchema.execute(query_str)
    expected_data = {
      "commonIngredientsWithLoad" => [
        {"name"=>"Corn"},
        {"name"=>"Butter"},
      ]
    }
    assert_equal expected_data, res["data"]

    expected_log = [
      [:mget, ["5", "6"]],
      [:mget, ["2", "3"]],
    ]
    assert_equal expected_log, database_log

    # Run the same test, but using `.request` from object_from_id
    database_log.clear
    res2 = FiberSchema.execute(query_str, context: { use_request: true })
    assert_equal expected_data, res2["data"]
    assert_equal expected_log, database_log
  end

  class UsageAnalyzer < GraphQL::Analysis::AST::Analyzer
    def initialize(query)
      @query = query
      @fields = Set.new
    end

    def on_enter_field(node, parent, visitor)
      args = @query.arguments_for(node, visitor.field_definition)
      # This bug has been around for a while,
      # see https://github.com/rmosolgo/graphql-ruby/issues/3321
      if args.is_a?(GraphQL::Execution::Lazy)
        args = args.value
      end
      @fields << [node.name, args.keys]
    end

    def result
      @fields
    end
  end

  it "Works with analyzing arguments with `loads:`, even with .request" do
    query_str = <<-GRAPHQL
    {
      commonIngredientsWithLoad(recipe1Id: 5, recipe2Id: 6) {
        name
      }
    }
    GRAPHQL
    query = GraphQL::Query.new(FiberSchema, query_str)
    results = GraphQL::Analysis::AST.analyze_query(query, [UsageAnalyzer])
    expected_results = [
      ["commonIngredientsWithLoad", [:recipe_1, :recipe_2]],
      ["name", []],
    ]
    assert_equal expected_results, results.first.to_a

    query2 = GraphQL::Query.new(FiberSchema, query_str, context: { use_request: true })
    result2 = GraphQL::Analysis::AST.analyze_query(query2, [UsageAnalyzer])
    assert_equal expected_results, result2.first.to_a
  end

  it "Works with input objects, load and request" do
    query_str = <<-GRAPHQL
    {
      commonIngredientsFromInputObject(input: { recipe1Id: 5, recipe2Id: 6 }) {
        name
      }
    }
    GRAPHQL
    res = FiberSchema.execute(query_str)
    expected_data = {
      "commonIngredientsFromInputObject" => [
        {"name"=>"Corn"},
        {"name"=>"Butter"},
      ]
    }
    assert_equal expected_data, res["data"]

    expected_log = [
      [:mget, ["5", "6"]],
      [:mget, ["2", "3"]],
    ]
    assert_equal expected_log, database_log


    # Run the same test, but using `.request` from object_from_id
    database_log.clear
    res2 = FiberSchema.execute(query_str, context: { use_request: true })
    assert_equal expected_data, res2["data"]
    assert_equal expected_log, database_log
  end

  it "Works with input objects using variables, load and request" do
    query_str = <<-GRAPHQL
    query($input: CommonIngredientsInput!) {
      commonIngredientsFromInputObject(input: $input) {
        name
      }
    }
    GRAPHQL
    res = FiberSchema.execute(query_str, variables: { input: { recipe1Id: 5, recipe2Id: 6 }})
    expected_data = {
      "commonIngredientsFromInputObject" => [
        {"name"=>"Corn"},
        {"name"=>"Butter"},
      ]
    }
    assert_equal expected_data, res["data"]

    expected_log = [
      [:mget, ["5", "6"]],
      [:mget, ["2", "3"]],
    ]
    assert_equal expected_log, database_log


    # Run the same test, but using `.request` from object_from_id
    database_log.clear
    res2 = FiberSchema.execute(query_str, context: { use_request: true }, variables: { input: { recipe1Id: 5, recipe2Id: 6 }})
    assert_equal expected_data, res2["data"]
    assert_equal expected_log, database_log
  end


  describe "example from #3314" do
    module Example
      class FooType < GraphQL::Schema::Object
        field :id, ID, null: false
      end

      class FooSource < GraphQL::Dataloader::Source
        def fetch(ids)
          ids.map { |id| OpenStruct.new(id: id) }
        end
      end

      class QueryType < GraphQL::Schema::Object
        field :foo, Example::FooType, null: true do
          argument :foo_id, GraphQL::Types::ID, required: false, loads: Example::FooType
          argument :use_load, GraphQL::Types::Boolean, required: false, default_value: false
        end

        def foo(use_load: false, foo: nil)
          if use_load
            dataloader.with(Example::FooSource).load("load")
          else
            dataloader.with(Example::FooSource).request("request")
          end
        end
      end

      class Schema < GraphQL::Schema
        query Example::QueryType
        use GraphQL::Dataloader

        def self.object_from_id(id, ctx)
          ctx.dataloader.with(Example::FooSource).request(id)
        end
      end
    end

    it "loads properly" do
      result = Example::Schema.execute(<<-GRAPHQL)
      {
        foo(useLoad: false, fooId: "Other") {
          __typename
          id
        }
        fooWithLoad: foo(useLoad: true, fooId: "Other") {
          __typename
          id
        }
      }
      GRAPHQL
      # This should not have a Lazy in it
      expected_result = {
        "data" => {
          "foo" => { "id" => "request", "__typename" => "Foo" },
          "fooWithLoad" => { "id" => "load", "__typename" => "Foo" },
        }
      }

      assert_equal expected_result, result.to_h
    end
  end

  class FiberErrorSchema < GraphQL::Schema
    class ErrorObject < GraphQL::Dataloader::Source
      def fetch(_)
        raise ArgumentError, "Nope"
      end
    end

    class Query < GraphQL::Schema::Object
      field :load, String, null: false
      field :load_all, String, null: false
      field :request, String, null: false
      field :request_all, String, null: false

      def load
        dataloader.with(ErrorObject).load(123)
      end

      def load_all
        dataloader.with(ErrorObject).load_all([123])
      end

      def request
        req = dataloader.with(ErrorObject).request(123)
        req.load
      end

      def request_all
        req = dataloader.with(ErrorObject).request_all([123])
        req.load
      end
    end

    use GraphQL::Dataloader
    query(Query)

    rescue_from(StandardError) do |err, obj, args, ctx, field|
      ctx[:errors] << "#{err.message} (#{field.owner.name}.#{field.graphql_name}, #{obj.inspect}, #{args.inspect})"
      nil
    end
  end

  it "Works with error handlers" do
    context = { errors: [] }

    res = FiberErrorSchema.execute("{ load loadAll request requestAll }", context: context)

    expected_errors = [
      "Nope (FiberErrorSchema::Query.load, nil, {})",
      "Nope (FiberErrorSchema::Query.loadAll, nil, {})",
      "Nope (FiberErrorSchema::Query.request, nil, {})",
      "Nope (FiberErrorSchema::Query.requestAll, nil, {})",
    ]

    assert_equal(nil, res["data"])
    assert_equal(expected_errors, context[:errors].sort)
  end
end
