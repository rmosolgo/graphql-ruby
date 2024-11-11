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

  class PreloadDynVisSchema < VisSchema
    use GraphQL::Schema::Visibility, profiles: { public: {}, admin: {} }, dynamic: true, preload: true
  end

  def exec_query(...)
    VisSchema.execute(...)
  end

  describe "top-level schema caches" do
    it "re-uses results" do
      assert_equal DynVisSchema.types.object_id, DynVisSchema.types.object_id
      assert_equal PreloadDynVisSchema.types.object_id, PreloadDynVisSchema.types.object_id
    end
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

    describe "when no profile is defined" do
      class NoProfileSchema < GraphQL::Schema
        class ExampleExtension < GraphQL::Schema::FieldExtension; end
        class OtherExampleExtension < GraphQL::Schema::FieldExtension; end

        class Query < GraphQL::Schema::Object
          field :str do
            type(String)
            extension(ExampleExtension)
          end
        end

        class Mutation < GraphQL::Schema::Object
          field :str do
            type(String)
            extension(ExampleExtension)
          end
        end

        class Subscription < GraphQL::Schema::Object
          field :str do
            type(String)
            extension(ExampleExtension)
          end
        end

        class OrphanType < GraphQL::Schema::Object
          field :str do
            type(String)
            extension(ExampleExtension)
            extension(OtherExampleExtension)
          end
        end
        # This one is added before `Visibility`
        subscription(Subscription)
        use GraphQL::Schema::Visibility, preload: true
        query { Query }
        mutation { Mutation }
        orphan_types(OrphanType)

        module CustomIntrospection
          class DynamicFields < GraphQL::Introspection::DynamicFields
            field :__hello do
              type(String)
              extension(OtherExampleExtension)
            end
          end
        end
      end

      it "still preloads" do
        assert_equal [], NoProfileSchema::Query.all_field_definitions.first.extensions.map(&:class)
        assert_equal [], NoProfileSchema::Mutation.all_field_definitions.first.extensions.map(&:class)
        NoProfileSchema.mutation
        assert_equal [NoProfileSchema::ExampleExtension], NoProfileSchema::Mutation.all_field_definitions.first.extensions.map(&:class)
        # Didn't load this:
        assert_equal [], NoProfileSchema::Query.all_field_definitions.first.extensions.map(&:class)

        NoProfileSchema.query
        assert_equal [NoProfileSchema::ExampleExtension], NoProfileSchema::Query.all_field_definitions.first.extensions.map(&:class)

        assert_equal [NoProfileSchema::ExampleExtension], NoProfileSchema::Subscription.all_field_definitions.first.extensions.map(&:class)
        assert_equal [NoProfileSchema::ExampleExtension, NoProfileSchema::OtherExampleExtension], NoProfileSchema::OrphanType.all_field_definitions.first.extensions.map(&:class)
        custom_int_field = NoProfileSchema::CustomIntrospection::DynamicFields.all_field_definitions.find { |f| f.original_name == :__hello }
        assert_equal [], custom_int_field.extensions
        NoProfileSchema.introspection(NoProfileSchema::CustomIntrospection)
        assert_equal [NoProfileSchema::OtherExampleExtension], custom_int_field.extensions.map(&:class)
      end
    end
  end
end
