# frozen_string_literal: true
require "spec_helper"

describe "Next Execution scoped context" do
  class NextScopedContextSchema < GraphQL::Schema
    AccountData = Struct.new(:id, :items)
    ItemData = Struct.new(:name)

    # The same item appears under every account, so scopes can't be told apart by object.
    SHARED_ITEM = ItemData.new("widget")

    def self.account_data
      [AccountData.new("a1", [SHARED_ITEM]), AccountData.new("a2", [SHARED_ITEM])]
    end

    module Priced
      include GraphQL::Schema::Interface
      field :priced_for, String, resolve_each: true

      def priced_for
        context[:account_id]
      end
    end

    class Item < GraphQL::Schema::Object
      implements Priced
      field :name, String, null: false

      def self.priced_for(_object, context)
        context[:account_id]
      end

      field :legacy_priced_for, String, resolve_legacy_instance_method: true

      def legacy_priced_for
        context[:account_id]
      end

      field :batch_priced_for, String, resolve_batch: true

      def self.batch_priced_for(objects, context)
        objects.map { context[:account_id] }
      end

      def batch_priced_for
        self.class.batch_priced_for([object], context).first
      end

      field :priced_for_with_tier, String, resolve_each: true

      def self.priced_for_with_tier(_object, context)
        "#{context[:account_id]}:#{context[:tier]}"
      end

      def priced_for_with_tier
        self.class.priced_for_with_tier(object, context)
      end
    end

    class ScopedItemsResolver < GraphQL::Schema::Resolver
      type [Item], null: false

      def resolve
        context.scoped_set!(:account_id, object.id)
        object.items
      end
    end

    class Account < GraphQL::Schema::Object
      field :id, ID, null: false

      field :resolved_items, resolver: ScopedItemsResolver

      field :items, [Item], null: false, resolve_each: true

      def self.items(object, context)
        context.scoped_set!(:account_id, object.id)
        object.items
      end

      def items
        self.class.items(object, context)
      end

      field :item_grid, [[Item]], null: false, resolve_each: true

      def self.item_grid(object, context)
        context.scoped_set!(:account_id, object.id)
        [object.items, object.items]
      end

      def item_grid
        self.class.item_grid(object, context)
      end

      field :priced, [Priced], null: false, resolve_each: true

      def self.priced(object, context)
        context.scoped_set!(:account_id, object.id)
        object.items
      end

      def priced
        self.class.priced(object, context)
      end

      field :tiered_items, [Item], null: false, resolve_each: true

      def self.tiered_items(object, context)
        context.scoped_merge!(account_id: object.id, tier: "gold")
        object.items
      end

      def tiered_items
        self.class.tiered_items(object, context)
      end

      field :own_scope, String, resolve_each: true

      def self.own_scope(object, context)
        context.scoped_set!(:account_id, object.id)
        context[:account_id]
      end

      def own_scope
        self.class.own_scope(object, context)
      end

      field :batch_items, [Item], null: false, resolve_batch: true

      def self.batch_items(objects, context)
        context.scoped_set!(:account_id, "batch")
        objects.map(&:items)
      end

      field :unscoped_items, [Item], null: false, resolve_each: true

      def self.unscoped_items(object, _context)
        object.items
      end

      def unscoped_items
        self.class.unscoped_items(object, context)
      end

      field :later_items, [Item], null: false, resolve_each: true

      def self.later_items(object, context)
        handle = context.scoped
        handle.set!(:account_id, object.id)
        object.items
      end

      def later_items
        self.class.later_items(object, context)
      end
    end

    class Query < GraphQL::Schema::Object
      field :accounts, [Account], null: false, resolve_static: true

      def self.accounts(_context)
        NextScopedContextSchema.account_data
      end

      def accounts
        self.class.accounts(context)
      end

      field :scoped_accounts, [Account], null: false, resolve_static: true

      def self.scoped_accounts(context)
        context.scoped_set!(:account_id, "root")
        NextScopedContextSchema.account_data
      end

      def scoped_accounts
        self.class.scoped_accounts(context)
      end
    end

    query(Query)
    use GraphQL::Execution::Next

    def self.resolve_type(_abs_type, _object, _context)
      Item
    end
  end

  def run_both(query_str)
    classic = NextScopedContextSchema.execute(query_str).to_h
    next_result = NextScopedContextSchema.execute_next(query_str).to_h
    [classic, next_result]
  end

  def values_by_account(result, field, item_field = "pricedFor", root: "accounts")
    result["data"][root].to_h do |account|
      [account["id"], account[field].flatten.map { |item| item[item_field] }]
    end
  end

  it "keeps resolve_each scoped values on each object's subtree" do
    classic, next_result = run_both("{ accounts { id items { name pricedFor } } }")
    assert_equal({ "a1" => ["a1"], "a2" => ["a2"] }, values_by_account(next_result, "items"))
    assert_equal classic, next_result
  end

  it "makes scoped values visible to legacy instance methods" do
    classic, next_result = run_both("{ accounts { id items { legacyPricedFor } } }")
    assert_equal({ "a1" => ["a1"], "a2" => ["a2"] }, values_by_account(next_result, "items", "legacyPricedFor"))
    assert_equal classic, next_result
  end

  it "scopes through nested lists" do
    classic, next_result = run_both("{ accounts { id itemGrid { pricedFor } } }")
    assert_equal({ "a1" => ["a1", "a1"], "a2" => ["a2", "a2"] }, values_by_account(next_result, "itemGrid"))
    assert_equal classic, next_result
  end

  it "scopes through abstract return types" do
    classic, next_result = run_both("{ accounts { id priced { pricedFor } } }")
    assert_equal({ "a1" => ["a1"], "a2" => ["a2"] }, values_by_account(next_result, "priced"))
    assert_equal classic, next_result
  end

  it "supports scoped_merge! with several keys" do
    classic, next_result = run_both("{ accounts { id tieredItems { pricedForWithTier } } }")
    assert_equal({ "a1" => ["a1:gold"], "a2" => ["a2:gold"] }, values_by_account(next_result, "tieredItems", "pricedForWithTier"))
    assert_equal classic, next_result
  end

  it "reads a value set by the same field" do
    classic, next_result = run_both("{ accounts { id ownScope } }")
    assert_equal [{ "id" => "a1", "ownScope" => "a1" }, { "id" => "a2", "ownScope" => "a2" }], next_result["data"]["accounts"]
    assert_equal classic, next_result
  end

  it "doesn't leak a value into sibling fields of the same object" do
    classic, next_result = run_both("{ accounts { id items { pricedFor } unscopedItems { pricedFor } } }")
    assert_equal({ "a1" => [nil], "a2" => [nil] }, values_by_account(next_result, "unscopedItems"))
    assert_equal classic, next_result
  end

  it "inherits values from ancestor fields and lets nearer scopes win" do
    classic, next_result = run_both("{ scopedAccounts { id items { pricedFor } unscopedItems { pricedFor } } }")
    assert_equal({ "a1" => ["a1"], "a2" => ["a2"] }, values_by_account(next_result, "items", root: "scopedAccounts"))
    assert_equal({ "a1" => ["root"], "a2" => ["root"] }, values_by_account(next_result, "unscopedItems", root: "scopedAccounts"))
    assert_equal classic, next_result
  end

  it "scopes values set in a resolver class to its object" do
    classic, next_result = run_both("{ accounts { id resolvedItems { pricedFor } } }")
    assert_equal({ "a1" => ["a1"], "a2" => ["a2"] }, values_by_account(next_result, "resolvedItems"))
    assert_equal classic, next_result
  end

  it "writes through a context.scoped handle to the object it was taken for" do
    classic, next_result = run_both("{ accounts { id laterItems { pricedFor } } }")
    assert_equal({ "a1" => ["a1"], "a2" => ["a2"] }, values_by_account(next_result, "laterItems"))
    assert_equal classic, next_result
  end

  it "applies a resolve_batch write to every object in the batch" do
    result = NextScopedContextSchema.execute_next("{ accounts { id batchItems { pricedFor } } }").to_h
    assert_equal({ "a1" => ["batch"], "a2" => ["batch"] }, values_by_account(result, "batchItems"))
  end

  it "returns a resolve_batch read when every object in the batch agrees" do
    classic, next_result = run_both("{ scopedAccounts { id unscopedItems { batchPricedFor } } }")
    assert_equal({ "a1" => ["root"], "a2" => ["root"] }, values_by_account(next_result, "unscopedItems", "batchPricedFor", root: "scopedAccounts"))
    assert_equal classic, next_result
  end

  it "raises on a resolve_batch read when objects in the batch have different values" do
    err = assert_raises(GraphQL::Error) do
      NextScopedContextSchema.execute_next("{ accounts { id items { batchPricedFor } } }")
    end
    assert_includes err.message, ":account_id"
    assert_includes err.message, "Item.batchPricedFor"
  end
end
