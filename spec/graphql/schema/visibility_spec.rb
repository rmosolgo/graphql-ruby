# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Visibility do
  class VisSchema < GraphQL::Schema
    class BaseField < GraphQL::Schema::Field
      def initialize(*args, admin_only: false, **kwargs, &block)
        super(*args, **kwargs, &block)
        @admin_only = admin_only
      end

      def visible?(ctx)
        super && (@admin_only ? !!ctx[:is_admin] : true)
      end
    end

    class BaseObject < GraphQL::Schema::Object
      field_class(BaseField)
    end

    class Product < BaseObject
      field :name, String
      field :price, Integer
      field :cost_of_goods_sold, Integer, admin_only: true
    end

    class Query < BaseObject
      field :products, [Product]

      def products
        [{ name: "Pool Noodle", price: 100, cost_of_goods_sold: 5 }]
      end
    end

    query(Query)
    use GraphQL::Schema::Visibility, profiles: { public: {}, admin: { is_admin: true } }, preload: true
  end

  class DynVisSchema < VisSchema
    use GraphQL::Schema::Visibility, profiles: { public: {}, admin: {} }, dynamic: true, preload: false
  end

  def exec_query(...)
    VisSchema.execute(...)
  end
  describe "running queries" do
    it "requires context[:visibility]" do
      err = assert_raises ArgumentError do
        exec_query("{ products { name } }")
      end
      expected_msg = "VisSchema expects a visibility profile, but `visibility_profile:` wasn't passed. Provide a `visibility_profile:` value or add `dynamic: true` to your visibility configuration."
      assert_equal expected_msg, err.message
    end

    it "requires a context[:visibility] which is on the list" do
      err = assert_raises ArgumentError do
        exec_query("{ products { name } }", visibility_profile: :nonsense )
      end
      expected_msg = "`:nonsense` isn't allowed for `visibility_profile:` (must be one of :public, :admin). Or, add `:nonsense` to the list of profiles in the schema definition."
      assert_equal expected_msg, err.message
    end

    it "permits `nil` when nil is on the list" do
      res = DynVisSchema.execute("{ products { name } }")
      assert_equal 1, res["data"]["products"].size
      assert_nil res.context.types.name
      assert_equal [], DynVisSchema.visibility.cached_profiles.keys
    end

    it "uses the named visibility" do
      res = exec_query("{ products { name } }", visibility_profile: :public)
      assert_equal ["Pool Noodle"], res["data"]["products"].map { |p| p["name"] }
      assert_equal :public, res.context.types.name
      assert res.context.types.equal?(VisSchema.visibility.cached_profiles[:public]), "It uses the cached instance"

      res = exec_query("{ products { costOfGoodsSold } }", visibility_profile: :public)
      assert_equal ["Field 'costOfGoodsSold' doesn't exist on type 'Product'"], res["errors"].map { |e| e["message"] }

      res = exec_query("{ products { name costOfGoodsSold } }", visibility_profile: :admin)
      assert_equal [{ "name" => "Pool Noodle", "costOfGoodsSold" => 5}], res["data"]["products"]
    end
  end

  describe "preloading profiles" do
    it "preloads when true" do
      assert_equal [:public, :admin], VisSchema.visibility.cached_profiles.keys, "preload: true"
      assert_equal 0, DynVisSchema.visibility.cached_profiles.size, "preload: false"
    end
  end
end
