# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Subset do
  class SubsetSchema < GraphQL::Schema
    class Recipe < GraphQL::Schema::Object
      subsets(:admin)
      field :ingredients, [String]
    end

    class Dish < GraphQL::Schema::Object
      field :price, Integer
      field :recipe, Recipe
    end

    class Query < GraphQL::Schema::Object
      field :dishes, [Dish]

      def dishes
        [
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
      end
    end

    query(Query)

    subset :admin
  end

  it "prints limited schema" do
    default_schema = SubsetSchema.to_definition
    admin_schema = SubsetSchema.to_definition(context: { schema_subset: :admin })
    refute_equal default_schema, admin_schema

    assert_includes admin_schema, "type Recipe"
    refute_includes default_schema, "type Recipe"
  end

  it "filters visibility at runtime" do
    query_str = "{ dishes { recipe { ingredients } } }"
    admin_res = SubsetSchema.execute(query_str, context: { schema_subset: :admin })
    assert_equal [3, 5], admin_res["data"]["dishes"].map { |d| d["recipe"]["ingredients"].size }

    default_res = SubsetSchema.execute(query_str, context: { schema_subset: :default })
    assert_equal ["Field 'recipe' doesn't exist on type 'Dish'"], default_res["errors"].map { |e| e["message"] }
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
