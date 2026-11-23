# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Visibility::Migration do
  class MigrationMismatchSchema < GraphQL::Schema
    class WardenOnlyHiddenField < GraphQL::Schema::Field
      def visible?(context)
        super && !context[:visibility_migration_warden_running]
      end
    end

    class Thing < GraphQL::Schema::Object
      field_class WardenOnlyHiddenField
      field :a, String, fallback_value: "a"
      field :b, String, fallback_value: "b"
    end

    class Query < GraphQL::Schema::Object
      field :thing, Thing, fallback_value: {}
    end

    query(Query)
    use GraphQL::Schema::Visibility, migration_errors: true
  end

  it "detects mismatches in list results" do
    query_str = '{ __type(name: "Thing") { fields { name } } }'
    err = assert_raises(GraphQL::Schema::Visibility::Migration::RuntimeTypesMismatchError) do
      MigrationMismatchSchema.execute(query_str)
    end
    assert_includes err.message, "Mismatch in types for `#fields("
  end

  it "doesn't raise when list results match" do
    query_str = '{ __type(name: "Query") { fields { name } } }'
    res = MigrationMismatchSchema.execute(query_str)
    assert_equal ["thing"], res["data"]["__type"]["fields"].map { |f| f["name"] }
  end

  describe "#equivalent_schema_members?" do
    let(:migration) { GraphQL::Schema::Visibility::Migration.allocate }

    it "compares the members of Sets" do
      assert migration.equivalent_schema_members?(Set[GraphQL::Types::String, GraphQL::Types::Int], Set[GraphQL::Types::Int, GraphQL::Types::String])
      refute migration.equivalent_schema_members?(Set[GraphQL::Types::String, GraphQL::Types::Int], Set[GraphQL::Types::String, GraphQL::Types::Float])
      refute migration.equivalent_schema_members?(Set[GraphQL::Types::String], Set[GraphQL::Types::String, GraphQL::Types::Int])
      refute migration.equivalent_schema_members?(Set[GraphQL::Types::String, GraphQL::Types::Int], Set[GraphQL::Types::String])
    end
  end
end
