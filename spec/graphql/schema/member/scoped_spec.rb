# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Member::Scoped do
  class ScopeSchema < GraphQL::Schema
    class BaseObject < GraphQL::Schema::Object
    end

    class Item < BaseObject
      def self.scope_items(items, context)
        if context[:french]
          items.select { |i| i.name == "Trombone" }
        elsif context[:english]
          items.select { |i| i.name == "Paperclip" }
        elsif context[:lazy]
          # return everything, but make the runtime wait for it,
          # and add a flag for confirming it was called
          ->() {
            context[:proc_called] = true
            items
          }
        else
          # boot everything
          items.reject { true }
        end
      end

      field :name, String, null: false
    end

    class FrenchItem < Item
      def self.scope_items(items, context)
        super(items, {french: true})
      end
    end

    class Equipment < BaseObject
      field :designation, String, null: false, method: :name
    end

    class BaseUnion < GraphQL::Schema::Union
    end

    class Thing < BaseUnion
      def self.scope_items(items, context)
        l = context.fetch(:first_letter)
        items.select { |i| i.name.start_with?(l) }
      end

      possible_types Item, Equipment

      def self.resolve_type(item, ctx)
        if item.name == "Turbine"
          Equipment
        else
          Item
        end
      end
    end

    class Query < BaseObject
      field :items, [Item], null: false
      field :unscoped_items, [Item], null: false,
        scope: false,
        resolver_method: :items

      field :nil_items, [Item]
      def nil_items
        nil
      end

      field :french_items, [FrenchItem], null: false,
        resolver_method: :items

      field :items_connection, Item.connection_type, null: false,
          resolver_method: :items

      def items
        [
          OpenStruct.new(name: "Trombone"),
          OpenStruct.new(name: "Paperclip"),
        ]
      end

      field :things, [Thing], null: false
      def things
        items + [OpenStruct.new(name: "Turbine")]
      end

      field :lazy_items, [Item], null: false
      field :lazy_items_connection, Item.connection_type, null: false, resolver_method: :lazy_items
      def lazy_items
        ->() { items }
      end
    end

    query(Query)
    lazy_resolve(Proc, :call)
  end

  describe ".scope_items(items, ctx)" do
    def get_item_names_with_context(ctx, field_name: "items")
      query_str = "
      {
        #{field_name} {
          name
        }
      }
      "
      res = ScopeSchema.execute(query_str, context: ctx)
      res["data"][field_name].map { |i| i["name"] }
    end

    it "applies to lists when scope: true" do
      assert_equal [], get_item_names_with_context({})
      assert_equal ["Trombone"], get_item_names_with_context({french: true})
      assert_equal ["Paperclip"], get_item_names_with_context({english: true})
    end

    it "is bypassed when scope: false" do
      assert_equal ["Trombone", "Paperclip"], get_item_names_with_context({}, field_name: "unscopedItems")
    end

    it "returns null when the value is nil" do
      query_str = "
      {
        nilItems {
          name
        }
      }
      "
      res = ScopeSchema.execute(query_str)
      refute res.key?("errors")
      assert_nil res.fetch("data").fetch("nilItems")
    end

    it "is inherited" do
      assert_equal ["Trombone"], get_item_names_with_context({}, field_name: "frenchItems")
    end

    it "is called for connection fields" do
      query_str = "
      {
        itemsConnection {
          edges {
            node {
              name
            }
          }
        }
      }
      "
      res = ScopeSchema.execute(query_str, context: {english: true})
      names = res["data"]["itemsConnection"]["edges"].map { |e| e["node"]["name"] }
      assert_equal ["Paperclip"], names

      query_str = "
      {
        itemsConnection {
          nodes {
            name
          }
        }
      }
      "
      res = ScopeSchema.execute(query_str, context: {english: true})
      names = res["data"]["itemsConnection"]["nodes"].map { |e| e["name"] }
      assert_equal ["Paperclip"], names
    end

    it "works for lazy connection values" do
      ctx = { lazy: true }
      query_str = "
      {
        itemsConnection {
          edges {
            node {
              name
            }
          }
        }
      }
      "
      res = ScopeSchema.execute(query_str, context: ctx)
      names = res["data"]["itemsConnection"]["edges"].map { |e| e["node"]["name"] }
      assert_equal ["Trombone", "Paperclip"], names
      assert_equal true, ctx[:proc_called]
    end

    it "works for lazy returned list values" do
      query_str = "
      {
        lazyItemsConnection {
          edges {
            node {
              name
            }
          }
        }
        lazyItems {
          name
        }
      }
      "
      res = ScopeSchema.execute(query_str, context: { french: true })
      names = res["data"]["lazyItemsConnection"]["edges"].map { |e| e["node"]["name"] }
      assert_equal ["Trombone"], names
      names2 = res["data"]["lazyItems"].map { |e| e["name"] }
      assert_equal ["Trombone"], names2
    end

    it "is called for abstract types" do
      query_str = "
      {
        things {
          ... on Item {
            name
          }
          ... on Equipment {
            designation
          }
        }
      }
      "
      res = ScopeSchema.execute(query_str, context: {first_letter: "T"})
      things = res["data"]["things"]
      assert_equal [{ "name" => "Trombone" }, {"designation" => "Turbine"}], things
    end

    it "works with lazy values" do
      ctx = {lazy: true}
      assert_equal ["Trombone", "Paperclip"], get_item_names_with_context(ctx)
      assert_equal true, ctx[:proc_called]
    end
  end

  describe "Schema::Field.scoped?" do
    it "prefers the override value" do
      assert_equal false, ScopeSchema::Query.fields["unscopedItems"].scoped?
    end

    it "defaults to true for lists" do
      assert_equal true, ScopeSchema::Query.fields["items"].type.list?
      assert_equal true, ScopeSchema::Query.fields["items"].scoped?
    end

    it "defaults to true for connections" do
      assert_equal true, ScopeSchema::Query.fields["itemsConnection"].connection?
      assert_equal true, ScopeSchema::Query.fields["itemsConnection"].scoped?
    end

    it "defaults to false for others" do
      assert_equal false, ScopeSchema::Item.fields["name"].scoped?
    end
  end
end
