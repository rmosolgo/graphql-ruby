# frozen_string_literal: true
require "spec_helper"
require "fiber"

describe GraphQL::Dataloader do
  class BatchedCallsCounter
    def initialize
      @count = 0
    end

    def increment
      @count += 1
    end

    attr_reader :count
  end

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

    class CustomBatchKeySource < GraphQL::Dataloader::Source
      def initialize(batch_key)
        @batch_key = batch_key
      end

      def self.batch_key_for(batch_key)
        Database.log << [:batch_key_for, batch_key]
        # Ignore it altogether
        :all_the_same
      end

      def fetch(keys)
        Database.mget(keys)
      end
    end

    class KeywordArgumentSource < GraphQL::Dataloader::Source
      def initialize(column:)
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

    class AuthorizedSource < GraphQL::Dataloader::Source
      def initialize(counter)
        @counter = counter
      end

      def fetch(recipes)
        @counter && @counter.increment
        recipes.map { true }
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
      def self.authorized?(obj, ctx)
        ctx.dataloader.with(AuthorizedSource, ctx[:batched_calls_counter]).load(obj)
      end

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

      field :ingredient, Ingredient do
        argument :id, ID
      end

      def ingredient(id:)
        dataloader.with(DataObject).load(id)
      end

      field :ingredient_by_name, Ingredient do
        argument :name, String
      end

      def ingredient_by_name(name:)
        dataloader.with(DataObject, :name).load(name)
      end

      field :nested_ingredient, Ingredient do
        argument :id, ID
      end

      def nested_ingredient(id:)
        dataloader.with(NestedDataObject).load(id)
      end

      field :slow_recipe, Recipe do
        argument :id, ID
      end

      def slow_recipe(id:)
        dataloader.with(SlowDataObject, id).load(id)
      end

      field :recipe, Recipe do
        argument :id, ID, loads: Recipe, as: :recipe
      end

      def recipe(recipe:)
        recipe
      end

      field :key_ingredient, Ingredient do
        argument :id, ID
      end

      def key_ingredient(id:)
        dataloader.with(KeywordArgumentSource, column: :id).load(id)
      end

      class RecipeIngredientInput < GraphQL::Schema::InputObject
        argument :id, ID
        argument :ingredient_number, Int
      end

      field :recipe_ingredient, Ingredient do
        argument :recipe, RecipeIngredientInput
      end

      def recipe_ingredient(recipe:)
        recipe_object = dataloader.with(DataObject).load(recipe[:id])
        ingredient_idx = recipe[:ingredient_number] - 1
        ingredient_id = recipe_object[:ingredient_ids][ingredient_idx]
        dataloader.with(DataObject).load(ingredient_id)
      end

      field :common_ingredients, [Ingredient] do
        argument :recipe_1_id, ID
        argument :recipe_2_id, ID
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
        argument :recipe_1_id, ID, loads: Recipe
        argument :recipe_2_id, ID, loads: Recipe
      end

      def common_ingredients_with_load(recipe_1:, recipe_2:)
        common_ids = recipe_1[:ingredient_ids] & recipe_2[:ingredient_ids]
        dataloader.with(DataObject).load_all(common_ids)
      end

      field :common_ingredients_from_input_object, [Ingredient], null: false do
        class CommonIngredientsInput < GraphQL::Schema::InputObject
          argument :recipe_1_id, ID, loads: Recipe
          argument :recipe_2_id, ID, loads: Recipe
        end
        argument :input, CommonIngredientsInput
      end


      def common_ingredients_from_input_object(input:)
        recipe_1 = input[:recipe_1]
        recipe_2 = input[:recipe_2]
        common_ids = recipe_1[:ingredient_ids] & recipe_2[:ingredient_ids]
        dataloader.with(DataObject).load_all(common_ids)
      end

      field :ingredient_with_custom_batch_key, Ingredient do
        argument :id, ID
        argument :batch_key, String
      end

      def ingredient_with_custom_batch_key(id:, batch_key:)
        dataloader.with(CustomBatchKeySource, batch_key).load(id)
      end
    end

    query(Query)

    class Mutation1 < GraphQL::Schema::Mutation
      argument :argument_1, String, prepare: ->(val, ctx) {
        raise FieldTestError
      }

      def resolve(argument_1:)
        argument_1
      end
    end

    class Mutation2 < GraphQL::Schema::Mutation
      argument :argument_2, String, prepare: ->(val, ctx) {
        raise FieldTestError
      }

      def resolve(argument_2:)
        argument_2
      end
    end

    class Mutation < GraphQL::Schema::Object
      field :mutation_1, mutation: Mutation1
      field :mutation_2, mutation: Mutation2
    end

    mutation(Mutation)

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

    class FieldTestError < StandardError; end

    rescue_from(FieldTestError) do |err, obj, args, ctx, field|
      errs = ctx[:errors] ||= []
      errs << "FieldTestError @ #{ctx[:current_path]}, #{field.path} / #{ctx[:current_field].path}"
      nil
    end
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

  def database_log
    FiberSchema::Database.log
  end

  before do
    database_log.clear
  end

  module DataloaderAssertions
    def self.included(child_class)
      child_class.class_eval do
        it "Works with request(...)" do
          res = schema.execute <<-GRAPHQL
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
          res = schema.execute <<-GRAPHQL
          {
            i1: ingredient(id: 1) { id name }
            i2: ingredient(id: 2) { name }
            r1: recipe(id: 5) {
              # This loads Ingredients 3 and 4
              ingredients { name }
            }
            # This loads Ingredient 7
            ri1: recipeIngredient(recipe: { id: 6, ingredientNumber: 3 }) {
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
              "7",                # recipeIngredient ingredient_id
            ]],
            [:mget, [
              "3", "4",           # The two unfetched ingredients the first recipe
            ]],
          ]
          assert_equal expected_log, database_log
        end

        it "caches and batch-loads across a multiplex" do
          context = {}
          result = schema.multiplex([
            { query: "{ i1: ingredient(id: 1) { name } i2: ingredient(id: 2) { name } }", },
            { query: "{ i2: ingredient(id: 2) { name } r1: recipe(id: 5) { ingredients { name } } }", },
            { query: "{ i1: ingredient(id: 1) { name } ri1: recipeIngredient(recipe: { id: 5, ingredientNumber: 2 }) { name } }", },
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
          res = schema.execute <<-GRAPHQL
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
          res = schema.execute <<-GRAPHQL
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
          schema.execute <<-GRAPHQL
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

          res = schema.execute(query_str)
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

          res = schema.execute(query_str)
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

          res = schema.execute(query_str)
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
          res2 = schema.execute(query_str, context: { use_request: true })
          assert_equal expected_data, res2["data"]
          assert_equal expected_log, database_log
        end

        it "works with sources that use keyword arguments in the initializer" do
          query_str = <<-GRAPHQL
          {
            keyIngredient(id: 1) {
              __typename
              name
            }
          }
          GRAPHQL

          res = schema.execute(query_str)
          expected_data = {
            "keyIngredient" => {
              "__typename" => "Grain",
              "name" => "Wheat",
            }
          }
          assert_equal expected_data, res["data"]
        end

        it "Works with analyzing arguments with `loads:`, even with .request" do
          query_str = <<-GRAPHQL
          {
            commonIngredientsWithLoad(recipe1Id: 5, recipe2Id: 6) {
              name
            }
          }
          GRAPHQL
          query = GraphQL::Query.new(schema, query_str)
          results = GraphQL::Analysis::AST.analyze_query(query, [UsageAnalyzer])
          expected_results = [
            ["commonIngredientsWithLoad", [:recipe_1, :recipe_2]],
            ["name", []],
          ]
          assert_equal expected_results, results.first.to_a

          query2 = GraphQL::Query.new(schema, query_str, context: { use_request: true })
          result2 = nil
          query2.context.dataloader.run_isolated do
            result2 = GraphQL::Analysis::AST.analyze_query(query2, [UsageAnalyzer])
          end

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
          res = schema.execute(query_str)
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
          res2 = schema.execute(query_str, context: { use_request: true })
          assert_equal expected_data, res2["data"]
          assert_equal expected_log, database_log
        end

        it "batches calls in .authorized?" do
          query_str = "{ r1: recipe(id: 5) { name } r2: recipe(id: 6) { name } }"
          context = { batched_calls_counter: BatchedCallsCounter.new }
          schema.execute(query_str, context: context)
          assert_equal 1, context[:batched_calls_counter].count

          query_str = "{ recipes { name } }"
          context = { batched_calls_counter: BatchedCallsCounter.new }
          schema.execute(query_str, context: context)
          assert_equal 1, context[:batched_calls_counter].count
        end

        it "Works with input objects using variables, load and request" do
          query_str = <<-GRAPHQL
          query($input: CommonIngredientsInput!) {
            commonIngredientsFromInputObject(input: $input) {
              name
            }
          }
          GRAPHQL
          res = schema.execute(query_str, variables: { input: { recipe1Id: 5, recipe2Id: 6 }})
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
          res2 = schema.execute(query_str, context: { use_request: true }, variables: { input: { recipe1Id: 5, recipe2Id: 6 }})
          assert_equal expected_data, res2["data"]
          assert_equal expected_log, database_log
        end

        it "supports general usage" do
          a = b = c = nil

          res = GraphQL::Dataloader.with_dataloading { |dataloader|
            dataloader.append_job {
              a = dataloader.with(FiberSchema::DataObject).load("1")
            }

            dataloader.append_job {
              b = dataloader.with(FiberSchema::DataObject).load("1")
            }

            dataloader.append_job {
              r1 = dataloader.with(FiberSchema::DataObject).request("2")
              r2 = dataloader.with(FiberSchema::DataObject).request("3")
              c = [
                r1.load,
                r2.load
              ]
            }

            :finished
          }

          assert_equal :finished, res
          assert_equal [[:mget, ["1", "2", "3"]]], database_log
          assert_equal "Wheat", a[:name]
          assert_equal "Wheat", b[:name]
          assert_equal ["Corn", "Butter"], c.map { |d| d[:name] }
        end

        it "uses .batch_key_for in source classes" do
          query_str = <<-GRAPHQL
          {
            i1: ingredientWithCustomBatchKey(id: 1, batchKey: "abc") { name }
            i2: ingredientWithCustomBatchKey(id: 2, batchKey: "def") { name }
            i3: ingredientWithCustomBatchKey(id: 3, batchKey: "ghi") { name }
          }
          GRAPHQL

          res = schema.execute(query_str)
          expected_data = { "i1" => { "name" => "Wheat" }, "i2" => { "name" => "Corn" }, "i3" => { "name" => "Butter" } }
          assert_equal expected_data, res["data"]
          expected_log = [
            # Each batch key is given to the source class:
            [:batch_key_for, "abc"],
            [:batch_key_for, "def"],
            [:batch_key_for, "ghi"],
            # But since they return the same value,
            # all keys are fetched in the same call:
            [:mget, ["1", "2", "3"]]
          ]
          assert_equal expected_log, database_log
        end

        it "uses cached values from .merge" do
          query_str = "{ ingredient(id: 1) { id name } }"
          assert_equal "Wheat", schema.execute(query_str)["data"]["ingredient"]["name"]
          assert_equal [[:mget, ["1"]]], database_log
          database_log.clear

          dataloader = schema.dataloader_class.new
          data_source = dataloader.with(FiberSchema::DataObject)
          data_source.merge({ "1" => { name: "Kamut", id: "1", type: "Grain" } })
          assert_equal "Kamut", data_source.load("1")[:name]
          res = schema.execute(query_str, context: { dataloader: dataloader })
          assert_equal [], database_log
          assert_equal "Kamut", res["data"]["ingredient"]["name"]
        end
      end
    end
  end

  let(:schema) { FiberSchema }
  include DataloaderAssertions

  if Fiber.respond_to?(:scheduler)
    describe "nonblocking: true" do
      let(:schema) { Class.new(FiberSchema) do
        use GraphQL::Dataloader, nonblocking: true
      end }

      before do
        Fiber.set_scheduler(::DummyScheduler.new)
      end

      after do
        Fiber.set_scheduler(nil)
      end

      include DataloaderAssertions
    end
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
        field :foo, Example::FooType do
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

  it "has proper context[:current_field]" do
    res = FiberSchema.execute("mutation { mutation1(argument1: \"abc\") { __typename } mutation2(argument2: \"def\") { __typename } }")
    assert_equal({"mutation1"=>nil, "mutation2"=>nil}, res["data"])
    expected_errors = [
      "FieldTestError @ [\"mutation2\"], Mutation.mutation2 / Mutation.mutation2",
      "FieldTestError @ [\"mutation1\"], Mutation.mutation1 / Mutation.mutation1",
    ]
    assert_equal expected_errors, res.context[:errors]
  end

  it "passes along throws" do
    value = catch(:hello) do
      dataloader = GraphQL::Dataloader.new
      dataloader.append_job do
        throw(:hello, :world)
      end
      dataloader.run
    end

    assert :world, value
  end

  class CanaryDataloader < GraphQL::Dataloader::NullDataloader
  end

  it "uses context[:dataloader] when given" do
    res = Class.new(GraphQL::Schema) do
      query_type = Class.new(GraphQL::Schema::Object) do
        graphql_name "Query"
      end
      query(query_type)
    end.execute("{ __typename }")
    assert_instance_of GraphQL::Dataloader::NullDataloader, res.context.dataloader
    res = FiberSchema.execute("{ __typename }")
    assert_instance_of GraphQL::Dataloader, res.context.dataloader
    refute res.context.dataloader.nonblocking?
    res = FiberSchema.execute("{ __typename }", context: { dataloader: CanaryDataloader.new } )
    assert_instance_of CanaryDataloader, res.context.dataloader

    if Fiber.respond_to?(:scheduler)
      Fiber.set_scheduler(::DummyScheduler.new)
      res = FiberSchema.execute("{ __typename }", context: { dataloader: GraphQL::Dataloader.new(nonblocking: true) })
      assert res.context.dataloader.nonblocking?

      res = FiberSchema.multiplex([{ query: "{ __typename }" }], context: { dataloader: GraphQL::Dataloader.new(nonblocking: true) })
      assert res[0].context.dataloader.nonblocking?
      Fiber.set_scheduler(nil)
    end
  end

  describe "#run_isolated" do
    module RunIsolated
      class CountSource < GraphQL::Dataloader::Source
        def fetch(ids)
          @count ||= 0
          @count += ids.size
          ids.map { |_id| @count }
        end
      end
    end

    it "uses its own queue" do
      dl = GraphQL::Dataloader.new
      result = {}
      dl.append_job { result[:a] = 1 }
      dl.append_job { result[:b] = 2 }
      dl.append_job { result[:c] = 3 }

      dl.run_isolated { result[:d] = 4 }

      assert_equal({ d: 4 }, result)

      dl.run_isolated {
        _r1 = dl.with(RunIsolated::CountSource).request(1)
        _r2 = dl.with(RunIsolated::CountSource).request(2)
        r3 = dl.with(RunIsolated::CountSource).request(3)
        # This is going to `Fiber.yield`
        result[:e] = r3.load
      }

      assert_equal({ d: 4, e: 3 }, result)
      dl.run
      assert_equal({ a: 1, b: 2, c: 3, d: 4, e: 3 }, result)
    end

    it "shares a cache" do
      dl = GraphQL::Dataloader.new
      result = {}
      dl.run_isolated {
        _r1 = dl.with(RunIsolated::CountSource).request(1)
        _r2 = dl.with(RunIsolated::CountSource).request(2)
        r3 = dl.with(RunIsolated::CountSource).request(3)
        # Run all three of the above requests:
        result[:a] = r3.load
      }

      dl.append_job {
        # This should return cached from above
        result[:b] = dl.with(RunIsolated::CountSource).load(1)
      }
      dl.append_job {
        # This one is run by itself
        result[:c] = dl.with(RunIsolated::CountSource).load(4)
      }

      assert_equal({ a: 3 }, result)
      dl.run
      assert_equal({ a: 3, b: 3, c: 4 }, result)
    end
  end

  describe "thread local variables" do
    module ThreadVariable
      class Type < GraphQL::Schema::Object
        field :key, String, null: false
        field :value, String, null: false
      end

      class Source < GraphQL::Dataloader::Source
        def fetch(keys)
          keys.map { |key| OpenStruct.new(key: key, value: Thread.current[key.to_sym]) }
        end
      end

      class QueryType < GraphQL::Schema::Object
        field :thread_var, ThreadVariable::Type do
          argument :key, GraphQL::Types::String
        end

        def thread_var(key:)
          dataloader.with(ThreadVariable::Source).load(key)
        end
      end

      class Schema < GraphQL::Schema
        query ThreadVariable::QueryType
        use GraphQL::Dataloader
      end
    end

    it "sets the parent thread locals in the execution fiber" do
      Thread.current[:test_thread_var] = 'foobarbaz'

      result = ThreadVariable::Schema.execute(<<-GRAPHQL)
      {
        threadVar(key: "test_thread_var") {
          key
          value
        }
      }
      GRAPHQL

      expected_result = {
        "data" => {
          "threadVar" => { "key" => "test_thread_var", "value" => "foobarbaz" }
        }
      }

      assert_equal expected_result, result.to_h
    end
  end

  describe "dataloader calls from inside sources" do
    class NestedDataloaderCallsSchema < GraphQL::Schema
      class Echo < GraphQL::Dataloader::Source
        def fetch(keys)
          keys
        end
      end

      class Nested < GraphQL::Dataloader::Source
        def fetch(keys)
          dataloader.with(Echo).load_all(keys)
        end
      end

      class Nested2 < GraphQL::Dataloader::Source
        def fetch(keys)
          dataloader.with(Nested).load_all(keys)
        end
      end

      class QueryType < GraphQL::Schema::Object
        field :nested, String
        field :nested2, String

        def nested
          dataloader.with(Nested).load("nested")
        end

        def nested2
          dataloader.with(Nested2).load("nested2")
        end
      end

      query QueryType
      use GraphQL::Dataloader
    end
  end

  it "loads data from inside source methods" do
    assert_equal({ "data" => { "nested" => "nested" } }, NestedDataloaderCallsSchema.execute("{ nested }"))
    assert_equal({ "data" => { "nested2" => "nested2" } }, NestedDataloaderCallsSchema.execute("{ nested2 }"))
    assert_equal({ "data" => { "nested" => "nested", "nested2" => "nested2" } }, NestedDataloaderCallsSchema.execute("{ nested nested2 }"))
  end

  describe "with lazy authorization hooks" do
    class LazyAuthHookSchema < GraphQL::Schema
      class Source < ::GraphQL::Dataloader::Source
        def fetch(ids)
          return ids.map {|i| i * 2}
        end
      end

      class BarType < GraphQL::Schema::Object
        field :id, Integer

        def id
          object
        end

        def self.authorized?(object, context)
          -> { true }
        end
      end

      class FooType < GraphQL::Schema::Object
        field :dataloader_value, BarType

        def self.authorized?(object, context)
          -> { true }
        end

        def dataloader_value
          dataloader.with(Source).load(1)
        end
      end

      class QueryType < GraphQL::Schema::Object
        field :foo, FooType

        def foo
          {}
        end
      end

      use GraphQL::Dataloader
      query QueryType
      lazy_resolve Proc, :call
    end

    it "resolves everything" do
      dataloader_query = """
        query {
          foo {
            dataloaderValue {
              id
            }
          }
        }
      """
      dataloader_result = LazyAuthHookSchema.execute(dataloader_query)
      assert_equal 2, dataloader_result["data"]["foo"]["dataloaderValue"]["id"]
    end
  end
end
