# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Tracing::Trace do
  it "has all its methods in the development cop" do
    trace_source = File.read("cop/development/trace_methods_cop.rb")
    superable_methods = GraphQL::Tracing::Trace.instance_methods(false).sort
    superable_methods_source = superable_methods.map { |m| "        #{m.inspect},\n" }.join
    assert_includes trace_source, superable_methods_source
  end


  describe "object hooks" do
    class ObjectHooksSchema < GraphQL::Schema
      module Node
        include GraphQL::Schema::Interface
        field :name, String
      end

      class Thing < GraphQL::Schema::Object
        implements Node
      end

      class Query < GraphQL::Schema::Object
        field :things, [Thing], resolve_static: true

        def self.things(context)
          [OpenStruct.new(name: "Thing One"), OpenStruct.new(name: "Thing Two")]
        end

        field :thing, Thing, resolve_static: true do
          argument :id, ID, loads: Thing, as: :thing
        end

        def self.thing(context, thing:)
          thing
        end

        field :thing_name, String, resolve_static: true do
          argument :thing_id, ID, loads: Thing
        end

        def self.thing_name(context, thing:)
          thing.name
        end

        field :node, Node, resolve_static: true do
          argument :id, ID, loads: Node, as: :node
        end

        def self.node(context, node:)
          node
        end
      end

      query(Query)
      use GraphQL::Execution::Next

      def self.object_from_id(id, ctx)
        OpenStruct.new(name: "Thing ##{id}")
      end

      def self.resolve_type(abs_type, obj, ctx)
        Thing
      end

      module LogTrace
        def objects(type, objects, context)
          context[:log] ||= []
          context[:log] << "#{objects.size} objects as #{type.graphql_name}"
          super
        end

        def object_loaded(argument_definition, object, context)
          context[:log] ||= []
          context[:log] << "#{argument_definition.path} loaded #{object.class}"
          super
        end
      end

      trace_with(LogTrace)
    end

    it "calls hooks with errors encountered during execution" do
      res = ObjectHooksSchema.execute_next("{ things { name } }")
      assert_equal ["Thing One", "Thing Two"], res["data"]["things"].map { |t| t["name"] }
      assert_equal ["1 objects as Query", "2 objects as Thing"], res.context[:log]

      res = ObjectHooksSchema.execute_next("{ thing(id: \"5\") { name } }")
      assert_equal "Thing #5", res["data"]["thing"]["name"]
      assert_equal ["1 objects as Query", "Query.thing.id loaded OpenStruct", "1 objects as Thing"], res.context[:log]

      res = ObjectHooksSchema.execute_next("{ thingName(thingId: \"77\") }")
      assert_equal "Thing #77", res["data"]["thingName"]
      assert_equal ["1 objects as Query", "Query.thingName.thingId loaded OpenStruct"], res.context[:log]

      res = ObjectHooksSchema.execute_next("{ node(id: \"33\") { name } }")
      assert_equal "Thing #33", res["data"]["node"]["name"]
      assert_equal ["1 objects as Query", "Query.node.id loaded OpenStruct", "1 objects as Thing"], res.context[:log]

      partial_res = res.query.run_partials([{ path: ["node"], object: OpenStruct.new(name: "Injected thing"), context: { log: [] } }])
      assert_equal "Injected thing", partial_res[0]["data"]["name"]
      assert_equal ["1 objects as Thing"], partial_res[0].context[:log]
    end
  end
end
