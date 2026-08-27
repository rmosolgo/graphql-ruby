# frozen_string_literal: true
require "spec_helper"
require "async" if RUBY_VERSION >= "3.2.0"

describe GraphQL::Current do
  describe "when no query is running" do
    it "returns nil for things" do
      assert_nil GraphQL::Current.operation_name
      assert_nil GraphQL::Current.field
      assert_nil GraphQL::Current.dataloader_source_class
    end
  end

  describe "in queries" do
    class CurrentSchema < GraphQL::Schema
      class ThingSource < GraphQL::Dataloader::Source
        def initialize(context)
          @context = context
        end

        def fetch(names)
          @context[:current_operation_name] << GraphQL::Current.operation_name
          @context[:current_source] << GraphQL::Current.dataloader_source_class
          names
        end
      end
      class Thing < GraphQL::Schema::Object
        field :name, String, resolve_static: :get_name

        def self.get_name(context)
          context[:current_field] << GraphQL::Current.field.path
          context.dataload(ThingSource, context, "thing")
        end

        def name
          self.class.get_name(context)
        end
      end
      class Query < GraphQL::Schema::Object
        field :thing, Thing, resolve_static: true
        field :operation_name_after_nested_query, String, resolve_static: true

        def self.thing(context)
          context[:current_field] << GraphQL::Current.field.path
          :thing
        end

        def thing
          self.class.thing(context)
        end

        def self.operation_name_after_nested_query(context)
          context.schema.public_send(context[:execute_method], "{ __typename }")
          GraphQL::Current.operation_name
        end

        def operation_name_after_nested_query
          self.class.operation_name_after_nested_query(context)
        end
      end

      query(Query)
      use GraphQL::Dataloader
      use GraphQL::Execution::Next
    end

    class AsyncCurrentSchema < CurrentSchema
      use GraphQL::Dataloader::AsyncDataloader
    end if RUBY_VERSION >= "3.2.0"

    it "returns execution information" do
      ctx = {
        current_field: [],
        current_source: [],
        current_operation_name: []
      }

      res = CurrentSchema.execute("query GetThingName { thing { name } }", context: ctx)
      assert_equal "thing", res["data"]["thing"]["name"]

      assert_equal ["GetThingName"], ctx[:current_operation_name]
      assert_equal [CurrentSchema::ThingSource], ctx[:current_source]
      assert_equal ["Query.thing", "Thing.name"], ctx[:current_field]
    end

    it "restores execution information after a nested query" do
      schemas = [CurrentSchema]
      schemas << AsyncCurrentSchema if RUBY_VERSION >= "3.2.0"

      schemas.product([:execute_legacy, :execute_next]).each do |schema, execute_method|
        result = schema.public_send(
          execute_method,
          "query OuterOperation { operationNameAfterNestedQuery }",
          context: { execute_method: execute_method },
        )

        assert_equal "OuterOperation", result["data"]["operationNameAfterNestedQuery"]
      end
    end
  end
end
