# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Subset do
  class SubsetSchema < GraphQL::Schema
    class Recipe < GraphQL::Schema::Object
      subsets(:admin)
      field :ingredients, [String]
    end

    class Dish < GraphQL::Schema::Object
      field :name, String
      field :recipe, Recipe
      field :cost_of_goods_sold, Integer, subsets: [:admin]
    end

    module Payable
      include GraphQL::Schema::Interface
      field :amount, Integer

      def self.resolve_type(obj, ctx)
        obj[:type]
      end
    end

    class Bill < GraphQL::Schema::Object
      implements Payable
    end

    class Bribe < GraphQL::Schema::Object
      implements Payable, subsets: [:admin]
    end

    class Expense < GraphQL::Schema::Union
      possible_types Dish
      possible_types Bribe, subsets: [:admin]
    end

    class Query < GraphQL::Schema::Object
      field :dishes, [Dish] do
        argument :yucky, Boolean, subsets: [:admin], required: false
      end

      def dishes(yucky: false)
        d = [
          {
            name: "Sauerkraut",
            recipe: {
              ingredients: ["Cabbage", "Salt", "Caraway Seed"]
            },
            cost_of_goods_sold: 50,
          },
          {
            name: "Curtido",
            recipe: {
              ingredients: ["Cabbage", "Carrot", "Onion", "Salt", "Oregano"]
            },
            cost_of_goods_sold: 54,
          },
        ]
        if yucky
          d << {
            name: "Asparagus Pudding",
            recipe: {
              ingredients: ["Asparagus", "Milk", "Eggs"],
            },
            cost_of_goods_sold: 125,
          }
        end
        d
      end

      field :expenses, [Expense]
      field :dummy_bribe, Bribe # just to connect it to the schema
      field :dummy_bill, Bill # just to connect it to the schema
      field :payables, [Payable]

      def payables
        [{type: Bill, amount: 3000}, {type: Bribe, amount: 5000}]
      end
    end

    query(Query)

    subset :admin
  end

  def exec_query(str, subset)
    SubsetSchema.execute(str, context: { schema_subset: subset })
  end

  it "prints limited schema" do
    default_schema = SubsetSchema.to_definition
    admin_schema = SubsetSchema.to_definition(context: { schema_subset: :admin })
    refute_equal default_schema, admin_schema

    assert_includes admin_schema, "type Recipe"
    refute_includes default_schema, "type Recipe"
  end

  it "works with no schema_subset" do
    query_str = "{ dishes { name } }"
    assert_equal 2, exec_query(query_str, :default)["data"]["dishes"].size
    assert_equal 2, exec_query(query_str, nil)["data"]["dishes"].size
  end

  describe "runtime visibility" do
    it "hides fields whose types are hidden" do
      query_str = "{ dishes { recipe { ingredients } } }"
      admin_res = exec_query(query_str, :admin)
      assert_equal [3, 5], admin_res["data"]["dishes"].map { |d| d["recipe"]["ingredients"].size }

      default_res = exec_query(query_str, :default)
      assert_equal ["Field 'recipe' doesn't exist on type 'Dish'"], default_res["errors"].map { |e| e["message"] }
    end

    it "hides types" do
      query_str = "{ __type(name: \"Recipe\") { name } }"
      admin_res = exec_query(query_str, :admin)
      assert_equal "Recipe", admin_res["data"]["__type"]["name"]

      default_res = exec_query(query_str, :default)
      assert_nil default_res["data"].fetch("__type")
    end

    it "hides arguments" do
      query_str = "{ dishes(yucky: true) { name } }"
      admin_res = exec_query(query_str, :admin)
      assert_equal "Asparagus Pudding", admin_res["data"]["dishes"][2]["name"]

      default_res = exec_query(query_str, :default)
      assert_equal ["Field 'dishes' doesn't accept argument 'yucky'"], default_res["errors"].map { |e| e["message"] }
    end

    it "hides fields" do
      query_str = "{ dishes { costOfGoodsSold } }"
      admin_res = exec_query(query_str, :admin)
      assert_equal [50, 54], admin_res["data"]["dishes"].map { |d| d["costOfGoodsSold"] }

      default_res = exec_query(query_str, :default)
      assert_equal ["Field 'costOfGoodsSold' doesn't exist on type 'Dish'"], default_res["errors"].map { |e| e["message"] }
    end

    it "hides union memberships" do
      query_str = "{ __type(name: \"Expense\") { possibleTypes { name } } }"
      admin_res = exec_query(query_str, :admin)
      assert_equal ["Bribe", "Dish"], admin_res["data"]["__type"]["possibleTypes"].map { |pt| pt["name"] }

      default_res = exec_query(query_str, :default)
      assert_equal ["Dish"], default_res["data"]["__type"]["possibleTypes"].map { |pt| pt["name"] }
      # But the type itself is still visible, only the membership is hidden:
      default_res2 = exec_query("{ __type(name: \"Bribe\") { name } }", :default)
      assert_equal "Bribe", default_res2["data"]["__type"]["name"]
    end

    it "hides inteface implementations" do
      query_str = "{ payables { ... on Bribe { amount } } }"
      admin_res = exec_query(query_str, :admin)
      assert_equal [nil, 5000], admin_res["data"]["payables"].map { |p| p["amount"] }

      default_res = exec_query(query_str, :default)
      assert_equal ["Fragment on Bribe can't be spread inside Payable", "Field 'amount' doesn't exist on type 'Bribe'"], default_res["errors"].map { |e| e["message"]}
    end
  end

  it "has a cached warden" do
    admin_subset = SubsetSchema.subset_for(:admin)
    default_subset = SubsetSchema.subset_for(:default)

    assert admin_subset.warden.visible_type?(SubsetSchema::Recipe)
    refute default_subset.warden.visible_type?(SubsetSchema::Recipe)
    refute SubsetSchema.visible?(SubsetSchema::Recipe, { schema_subset: :default })
    refute SubsetSchema.visible?(SubsetSchema::Recipe, {})
  end
end
