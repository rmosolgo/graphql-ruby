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
            }
          },
          {
            name: "Curtido",
            recipe: {
              ingredients: ["Cabbage", "Carrot", "Onion", "Salt", "Oregano"]
            }
          },
        ]
        if yucky
          d << {
            name: "Asparagus Pudding",
            recipe: {
              ingredients: ["Asparagus", "Milk", "Eggs"],
            }
          }
        end
        d
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

  describe "runtime visibility" do
    it "hides fields whose types are hidden" do
      query_str = "{ dishes { recipe { ingredients } } }"
      admin_res = exec_query(query_str, :admin)
      assert_equal [3, 5], admin_res["data"]["dishes"].map { |d| d["recipe"]["ingredients"].size }

      default_res = exec_query(query_str, :default)
      assert_equal ["Field 'recipe' doesn't exist on type 'Dish'"], default_res["errors"].map { |e| e["message"] }
    end

    it "hides arguments" do
      query_str = "{ dishes(yucky: true) { name } }"
      admin_res = exec_query(query_str, :admin)
      assert_equal "Asparagus Pudding", admin_res["data"]["dishes"][2]["name"]

      default_res = exec_query(query_str, :default)
      assert_equal ["Field 'dishes' doesn't accept argument 'yucky'"], default_res["errors"].map { |e| e["message"] }
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
