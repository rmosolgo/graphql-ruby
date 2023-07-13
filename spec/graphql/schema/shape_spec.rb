# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Shape do
  class ShapeSchema < GraphQL::Schema
    class Recipe < GraphQL::Schema::Object
      shapes(:admin)
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

    shape :admin
  end

  it "prints limited schema" do
    default_schema = ShapeSchema.to_definition
    admin_schema = ShapeSchema.to_definition(context: { schema_shape: :admin })
    refute_equal default_schema, admin_schema

    assert_includes admin_schema, "type Recipe"
    refute_includes default_schema, "type Recipe"
  end

  it "filters visibility at runtime" do
    query_str = "{ dishes { recipe { ingredients } } }"
    admin_res = ShapeSchema.execute(query_str, context: { schema_shape: :admin })
    assert_equal [3, 5], admin_res["data"]["dishes"].map { |d| d["recipe"]["ingredients"].size }

    default_res = ShapeSchema.execute(query_str, context: { schema_shape: :default })
    assert_equal ["Field 'recipe' doesn't exist on type 'Dish'"], default_res["errors"].map { |e| e["message"] }
  end

  it "has a cached warden" do
    admin_shape = ShapeSchema.shape_for(:admin)
    default_shape = ShapeSchema.shape_for(:default)

    assert admin_shape.warden.visible_type?(ShapeSchema::Recipe)
    refute default_shape.warden.visible_type?(ShapeSchema::Recipe)
    refute ShapeSchema.visible?(ShapeSchema::Recipe, { shape_name: :default })
    refute ShapeSchema.visible?(ShapeSchema::Recipe, {})
  end
end
