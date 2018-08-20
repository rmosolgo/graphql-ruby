# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Authorization do
  module AuthTest
    class Box
      attr_reader :value
      def initialize(value:)
        @value = value
      end
    end

    class BaseArgument < GraphQL::Schema::Argument
      def visible?(context)
        super && (context[:hide] ? @name != "hidden" : true)
      end

      def accessible?(context)
        super && (context[:hide] ? @name != "inaccessible" : true)
      end

      def authorized?(parent_object, context)
        super && parent_object != :hide2
      end
    end

    class BaseField < GraphQL::Schema::Field
      def initialize(*args, edge_class: nil, **kwargs, &block)
        @edge_class = edge_class
        super(*args, **kwargs, &block)
      end

      def to_graphql
        field_defn = super
        if @edge_class
          field_defn.edge_class = @edge_class
        end
        field_defn
      end

      argument_class BaseArgument
      def visible?(context)
        super && (context[:hide] ? @name != "hidden" : true)
      end

      def accessible?(context)
        super && (context[:hide] ? @name != "inaccessible" : true)
      end

      def authorized?(object, context)
        super && object != :hide
      end
    end

    class BaseObject < GraphQL::Schema::Object
      field_class BaseField
    end

    module BaseInterface
      include GraphQL::Schema::Interface
    end

    class BaseEnumValue < GraphQL::Schema::EnumValue
      def initialize(*args, role: nil, **kwargs)
        @role = role
        super(*args, **kwargs)
      end

      def visible?(context)
        super && (context[:hide] ? @role != :hidden : true)
      end
    end

    class BaseEnum < GraphQL::Schema::Enum
      enum_value_class(BaseEnumValue)
    end

    module HiddenInterface
      include BaseInterface

      def self.visible?(ctx)
        super && !ctx[:hide]
      end

      def self.resolve_type(obj, ctx)
        HiddenObject
      end
    end

    module HiddenDefaultInterface
      include BaseInterface
      # visible? will call the super method
      def self.resolve_type(obj, ctx)
        HiddenObject
      end
    end

    class HiddenObject < BaseObject
      implements HiddenInterface
      implements HiddenDefaultInterface
      def self.visible?(ctx)
        super && !ctx[:hide]
      end
    end

    class RelayObject < BaseObject
      def self.visible?(ctx)
        super && !ctx[:hidden_relay]
      end

      def self.accessible?(ctx)
        super && !ctx[:inaccessible_relay]
      end

      def self.authorized?(_val, ctx)
        super && !ctx[:unauthorized_relay]
      end
    end

    # TODO test default behavior for abstract types,
    # that they check their concrete types
    module InaccessibleInterface
      include BaseInterface

      def self.accessible?(ctx)
        super && !ctx[:hide]
      end

      def self.resolve_type(obj, ctx)
        InaccessibleObject
      end
    end

    module InaccessibleDefaultInterface
      include BaseInterface
      # accessible? will call the super method
      def self.resolve_type(obj, ctx)
        InaccessibleObject
      end
    end

    class InaccessibleObject < BaseObject
      implements InaccessibleInterface
      implements InaccessibleDefaultInterface
      def self.accessible?(ctx)
        super && !ctx[:hide]
      end
    end

    class UnauthorizedObject < BaseObject
      def self.authorized?(value, context)
        super && !context[:hide]
      end
    end

    class UnauthorizedBox < BaseObject
      # Hide `"a"`
      def self.authorized?(value, context)
        super && value != "a"
      end

      field :value, String, null: false, method: :object
    end

    module UnauthorizedInterface
      include BaseInterface

      def self.resolve_type(obj, ctx)
        if obj.is_a?(String)
          UnauthorizedCheckBox
        else
          raise "Unexpected value: #{obj.inspect}"
        end
      end
    end

    class UnauthorizedCheckBox < BaseObject
      implements UnauthorizedInterface
      # This authorized check returns a lazy object, it should be synced by the runtime.
      def self.authorized?(value, context)
        if !value.is_a?(String)
          raise "Unexpected box value: #{value.inspect}"
        end
        is_authed = super && value != "a"
        # Make it many levels nested just to make sure we support nested lazy objects
        Box.new(value: Box.new(value: Box.new(value: Box.new(value: is_authed))))
      end

      field :value, String, null: false, method: :object
    end

    class IntegerObject < BaseObject
      def self.authorized?(obj, ctx)
        if !obj.is_a?(Integer)
          raise "Unexpected IntegerObject: #{obj}"
        end
        is_allowed = !(ctx[:unauthorized_relay] || obj == ctx[:exclude_integer])
        Box.new(value: Box.new(value: is_allowed))
      end
      field :value, Integer, null: false, method: :object
    end

    class IntegerObjectEdge < GraphQL::Types::Relay::BaseEdge
      node_type(IntegerObject)
    end

    class IntegerObjectConnection < GraphQL::Types::Relay::BaseConnection
      edge_type(IntegerObjectEdge)
    end

    # This object responds with `replaced => false`,
    # but if its replacement value is used, it gives `replaced => true`
    class Replaceable
      def replacement
        { replaced: true }
      end

      def replaced
        false
      end
    end

    class ReplacedObject < BaseObject
      def self.authorized?(obj, ctx)
        super && !ctx[:replace_me]
      end

      field :replaced, Boolean, null: false
    end

    class LandscapeFeature < BaseEnum
      value "MOUNTAIN"
      value "STREAM", role: :unauthorized
      value "FIELD", role: :inaccessible
      value "TAR_PIT", role: :hidden
    end

    class Query < BaseObject
      field :hidden, Integer, null: false
      field :unauthorized, Integer, null: true, method: :object
      field :int2, Integer, null: true do
        argument :int, Integer, required: false
        argument :hidden, Integer, required: false
        argument :inaccessible, Integer, required: false
        argument :unauthorized, Integer, required: false
      end

      def int2(**args)
        args[:unauthorized] || 1
      end

      field :landscape_feature, LandscapeFeature, null: false do
        argument :string, String, required: false
        argument :enum, LandscapeFeature, required: false
      end

      def landscape_feature(string: nil, enum: nil)
        string || enum
      end

      field :landscape_features, [LandscapeFeature], null: false do
        argument :strings, [String], required: false
        argument :enums, [LandscapeFeature], required: false
      end

      def landscape_features(strings: [], enums: [])
        strings + enums
      end

      def empty_array; []; end
      field :hidden_object, HiddenObject, null: false, method: :itself
      field :hidden_interface, HiddenInterface, null: false, method: :itself
      field :hidden_default_interface, HiddenDefaultInterface, null: false, method: :itself
      field :hidden_connection, RelayObject.connection_type, null: :false, method: :empty_array
      field :hidden_edge, RelayObject.edge_type, null: :false, method: :edge_object

      field :inaccessible, Integer, null: false, method: :object_id
      field :inaccessible_object, InaccessibleObject, null: false, method: :itself
      field :inaccessible_interface, InaccessibleInterface, null: false, method: :itself
      field :inaccessible_default_interface, InaccessibleDefaultInterface, null: false, method: :itself
      field :inaccessible_connection, RelayObject.connection_type, null: :false, method: :empty_array
      field :inaccessible_edge, RelayObject.edge_type, null: :false, method: :edge_object

      field :unauthorized_object, UnauthorizedObject, null: true, method: :itself
      field :unauthorized_connection, RelayObject.connection_type, null: false, method: :array_with_item
      field :unauthorized_edge, RelayObject.edge_type, null: false, method: :edge_object

      def edge_object
        OpenStruct.new(node: 100)
      end

      def array_with_item
        [1]
      end

      field :unauthorized_lazy_box, UnauthorizedBox, null: true do
        argument :value, String, required: true
      end
      def unauthorized_lazy_box(value:)
        # Make it extra nested, just for good measure.
        Box.new(value: Box.new(value: value))
      end
      field :unauthorized_list_items, [UnauthorizedObject], null: true
      def unauthorized_list_items
        [self, self]
      end

      field :unauthorized_lazy_check_box, UnauthorizedCheckBox, null: true, method: :unauthorized_lazy_box do
        argument :value, String, required: true
      end

      field :unauthorized_interface, UnauthorizedInterface, null: true, method: :unauthorized_lazy_box do
        argument :value, String, required: true
      end

      field :unauthorized_lazy_list_interface, [UnauthorizedInterface, null: true], null: true

      def unauthorized_lazy_list_interface
        ["z", Box.new(value: Box.new(value: "z2")), "a", Box.new(value: "a")]
      end

      field :integers, IntegerObjectConnection, null: false

      def integers
        [1,2,3]
      end

      field :lazy_integers, IntegerObjectConnection, null: false

      def lazy_integers
        Box.new(value: Box.new(value: [1,2,3]))
      end

      field :replaced_object, ReplacedObject, null: false
      def replaced_object
        Replaceable.new
      end
    end

    class DoHiddenStuff < GraphQL::Schema::RelayClassicMutation
      def self.visible?(ctx)
        super && (ctx[:hidden_mutation] ? false : true)
      end
    end

    class DoHiddenStuff2 < GraphQL::Schema::Mutation
      def self.visible?(ctx)
        super && !ctx[:hidden_mutation]
      end
    end

    class DoInaccessibleStuff < GraphQL::Schema::RelayClassicMutation
      def self.accessible?(ctx)
        super && (ctx[:inaccessible_mutation] ? false : true)
      end
    end

    class DoUnauthorizedStuff < GraphQL::Schema::RelayClassicMutation
      def self.authorized?(obj, ctx)
        super && (ctx[:unauthorized_mutation] ? false : true)
      end
    end

    class Mutation < BaseObject
      field :do_hidden_stuff, mutation: DoHiddenStuff
      field :do_hidden_stuff2, mutation: DoHiddenStuff2
      field :do_inaccessible_stuff, mutation: DoInaccessibleStuff
      field :do_unauthorized_stuff, mutation: DoUnauthorizedStuff
    end

    class Schema < GraphQL::Schema
      query(Query)
      mutation(Mutation)

      lazy_resolve(Box, :value)

      def self.unauthorized_object(err)
        if err.object.respond_to?(:replacement)
          err.object.replacement
        else
          raise GraphQL::ExecutionError, "Unauthorized #{err.type.graphql_name}: #{err.object}"
        end
      end

      # use GraphQL::Backtrace
    end
  end

  def auth_execute(*args)
    AuthTest::Schema.execute(*args)
  end

  describe "applying the visible? method" do
    it "works in queries" do
      res = auth_execute(" { int int2 } ", context: { hide: true })
      assert_equal 1, res["errors"].size
    end

    it "applies return type visibility to fields" do
      error_queries = {
        "hiddenObject" => "{ hiddenObject { __typename } }",
        "hiddenInterface" => "{ hiddenInterface { __typename } }",
        "hiddenDefaultInterface" => "{ hiddenDefaultInterface { __typename } }",
      }

      error_queries.each do |name, q|
        hidden_res = auth_execute(q, context: { hide: true})
        assert_equal ["Field '#{name}' doesn't exist on type 'Query'"], hidden_res["errors"].map { |e| e["message"] }

        visible_res = auth_execute(q)
        # Both fields exist; the interface resolves to the object type, though
        assert_equal "HiddenObject", visible_res["data"][name]["__typename"]
      end
    end

    it "uses the mutation for derived fields, inputs and outputs" do
      query = "mutation { doHiddenStuff(input: {}) { __typename } }"
      res = auth_execute(query, context: { hidden_mutation: true })
      assert_equal ["Field 'doHiddenStuff' doesn't exist on type 'Mutation'"], res["errors"].map { |e| e["message"] }

      # `#resolve` isn't implemented, so this errors out:
      assert_raises NotImplementedError do
        auth_execute(query)
      end

      introspection_q = <<-GRAPHQL
        {
          t1: __type(name: "DoHiddenStuffInput") { name }
          t2: __type(name: "DoHiddenStuffPayload") { name }
        }
      GRAPHQL
      hidden_introspection_res = auth_execute(introspection_q, context: { hidden_mutation: true })
      assert_nil hidden_introspection_res["data"]["t1"]
      assert_nil hidden_introspection_res["data"]["t2"]

      visible_introspection_res = auth_execute(introspection_q)
      assert_equal "DoHiddenStuffInput", visible_introspection_res["data"]["t1"]["name"]
      assert_equal "DoHiddenStuffPayload", visible_introspection_res["data"]["t2"]["name"]
    end

    it "works with Schema::Mutation" do
      query = "mutation { doHiddenStuff2 { __typename } }"
      res = auth_execute(query, context: { hidden_mutation: true })
      assert_equal ["Field 'doHiddenStuff2' doesn't exist on type 'Mutation'"], res["errors"].map { |e| e["message"] }

      # `#resolve` isn't implemented, so this errors out:
      assert_raises NotImplementedError do
        auth_execute(query)
      end
    end

    it "uses the base type for edges and connections" do
      query = <<-GRAPHQL
      {
        hiddenConnection { __typename }
        hiddenEdge { __typename }
      }
      GRAPHQL

      hidden_res = auth_execute(query, context: { hidden_relay: true })
      assert_equal 2, hidden_res["errors"].size

      visible_res = auth_execute(query)
      assert_equal "RelayObjectConnection", visible_res["data"]["hiddenConnection"]["__typename"]
      assert_equal "RelayObjectEdge", visible_res["data"]["hiddenEdge"]["__typename"]
    end

    it "treats hidden enum values as non-existant, even in lists" do
      hidden_res_1 = auth_execute <<-GRAPHQL, context: { hide: true }
      {
        landscapeFeature(enum: TAR_PIT)
      }
      GRAPHQL

      assert_equal ["Argument 'enum' on Field 'landscapeFeature' has an invalid value. Expected type 'LandscapeFeature'."], hidden_res_1["errors"].map { |e| e["message"] }

      hidden_res_2 = auth_execute <<-GRAPHQL, context: { hide: true }
      {
        landscapeFeatures(enums: [STREAM, TAR_PIT])
      }
      GRAPHQL

      assert_equal ["Argument 'enums' on Field 'landscapeFeatures' has an invalid value. Expected type '[LandscapeFeature!]'."], hidden_res_2["errors"].map { |e| e["message"] }

      success_res = auth_execute <<-GRAPHQL, context: { hide: false }
      {
        landscapeFeature(enum: TAR_PIT)
        landscapeFeatures(enums: [STREAM, TAR_PIT])
      }
      GRAPHQL

      assert_equal "TAR_PIT", success_res["data"]["landscapeFeature"]
      assert_equal ["STREAM", "TAR_PIT"], success_res["data"]["landscapeFeatures"]
    end

    it "refuses to resolve to hidden enum values" do
      assert_raises(GraphQL::EnumType::UnresolvedValueError) do
        auth_execute <<-GRAPHQL, context: { hide: true }
        {
          landscapeFeature(string: "TAR_PIT")
        }
        GRAPHQL
      end

      assert_raises(GraphQL::EnumType::UnresolvedValueError) do
        auth_execute <<-GRAPHQL, context: { hide: true }
        {
          landscapeFeatures(strings: ["STREAM", "TAR_PIT"])
        }
        GRAPHQL
      end
    end

    it "works in introspection" do
      res = auth_execute <<-GRAPHQL, context: { hide: true, hidden_mutation: true }
        {
          query: __type(name: "Query") {
            fields {
              name
              args { name }
            }
          }

          hiddenObject: __type(name: "HiddenObject") { name }
          hiddenInterface: __type(name: "HiddenInterface") { name }
          landscapeFeatures: __type(name: "LandscapeFeature") { enumValues { name } }
        }
      GRAPHQL
      query_field_names = res["data"]["query"]["fields"].map { |f| f["name"] }
      refute_includes query_field_names, "int"
      int2_arg_names = res["data"]["query"]["fields"].find { |f| f["name"] == "int2" }["args"].map { |a| a["name"] }
      assert_equal ["int", "inaccessible", "unauthorized"], int2_arg_names

      assert_nil res["data"]["hiddenObject"]
      assert_nil res["data"]["hiddenInterface"]

      visible_landscape_features = res["data"]["landscapeFeatures"]["enumValues"].map { |v| v["name"] }
      assert_equal ["MOUNTAIN", "STREAM", "FIELD"], visible_landscape_features
    end
  end

  describe "applying the accessible? method" do
    it "works with fields and arguments" do
      queries = {
        "{ inaccessible }" => ["Some fields in this query are not accessible: inaccessible"],
        "{ int2(inaccessible: 1) }" => ["Some fields in this query are not accessible: int2"],
      }

      queries.each do |query_str, errors|
        res = auth_execute(query_str, context: { hide: true })
        assert_equal errors, res.fetch("errors").map { |e| e["message"] }

        res = auth_execute(query_str, context: { hide: false })
        refute res.key?("errors")
      end
    end

    it "works with return types" do
      queries = {
        "{ inaccessibleObject { __typename } }" => ["Some fields in this query are not accessible: inaccessibleObject"],
        "{ inaccessibleInterface { __typename } }" => ["Some fields in this query are not accessible: inaccessibleInterface"],
        "{ inaccessibleDefaultInterface { __typename } }" => ["Some fields in this query are not accessible: inaccessibleDefaultInterface"],
      }

      queries.each do |query_str, errors|
        res = auth_execute(query_str, context: { hide: true })
        assert_equal errors, res["errors"].map { |e| e["message"] }

        res = auth_execute(query_str, context: { hide: false })
        refute res.key?("errors")
      end
    end

    it "works with mutations" do
      query = "mutation { doInaccessibleStuff(input: {}) { __typename } }"
      res = auth_execute(query, context: { inaccessible_mutation: true })
      assert_equal ["Some fields in this query are not accessible: doInaccessibleStuff"], res["errors"].map { |e| e["message"] }

      assert_raises NotImplementedError do
        auth_execute(query)
      end
    end

    it "works with edges and connections" do
      query = <<-GRAPHQL
      {
        inaccessibleConnection { __typename }
        inaccessibleEdge { __typename }
      }
      GRAPHQL

      inaccessible_res = auth_execute(query, context: { inaccessible_relay: true })
      assert_equal ["Some fields in this query are not accessible: inaccessibleConnection, inaccessibleEdge"], inaccessible_res["errors"].map { |e| e["message"] }

      accessible_res = auth_execute(query)
      refute accessible_res.key?("errors")
    end
  end

  describe "applying the authorized? method" do
    it "halts on unauthorized objects" do
      query = "{ unauthorizedObject { __typename } }"
      hidden_response = auth_execute(query, context: { hide: true })
      assert_nil hidden_response["data"].fetch("unauthorizedObject")
      visible_response = auth_execute(query, context: {})
      assert_equal({ "__typename" => "UnauthorizedObject" }, visible_response["data"]["unauthorizedObject"])
    end

    it "halts on unauthorized mutations" do
      query = "mutation { doUnauthorizedStuff(input: {}) { __typename } }"
      res = auth_execute(query, context: { unauthorized_mutation: true })
      assert_nil res["data"].fetch("doUnauthorizedStuff")
      assert_raises NotImplementedError do
        auth_execute(query)
      end
    end

    it "halts on unauthorized fields, using the parent object" do
      query = "{ unauthorized }"
      hidden_response = auth_execute(query, root_value: :hide)
      assert_nil hidden_response["data"].fetch("unauthorized")
      visible_response = auth_execute(query, root_value: 1)
      assert_equal 1, visible_response["data"]["unauthorized"]
    end

    it "halts on unauthorized arguments, using the parent object" do
      query = "{ int2(unauthorized: 5) }"
      hidden_response = auth_execute(query, root_value: :hide2)
      assert_nil hidden_response["data"].fetch("int2")
      visible_response = auth_execute(query)
      assert_equal 5, visible_response["data"]["int2"]
    end

    it "works with edges and connections" do
      query = <<-GRAPHQL
      {
        unauthorizedConnection {
          __typename
          edges {
            __typename
            node {
              __typename
            }
          }
          nodes {
            __typename
          }
        }
        unauthorizedEdge {
          __typename
          node {
            __typename
          }
        }
      }
      GRAPHQL

      unauthorized_res = auth_execute(query, context: { unauthorized_relay: true })
      conn = unauthorized_res["data"].fetch("unauthorizedConnection")
      assert_equal "RelayObjectConnection", conn.fetch("__typename")
      assert_equal nil, conn.fetch("nodes")
      assert_equal [{"node" => nil, "__typename" => "RelayObjectEdge"}], conn.fetch("edges")

      edge = unauthorized_res["data"].fetch("unauthorizedEdge")
      assert_nil edge.fetch("node")
      assert_equal "RelayObjectEdge", edge["__typename"]

      unauthorized_object_paths = [
        ["unauthorizedConnection", "edges", 0, "node"],
        ["unauthorizedConnection", "nodes"],
        ["unauthorizedEdge", "node"]
      ]

      assert_equal unauthorized_object_paths, unauthorized_res["errors"].map { |e| e["path"] }

      authorized_res = auth_execute(query)
      conn = authorized_res["data"].fetch("unauthorizedConnection")
      assert_equal "RelayObjectConnection", conn.fetch("__typename")
      assert_equal [{"__typename"=>"RelayObject"}], conn.fetch("nodes")
      assert_equal [{"node" => {"__typename" => "RelayObject"}, "__typename" => "RelayObjectEdge"}], conn.fetch("edges")

      edge = authorized_res["data"].fetch("unauthorizedEdge")
      assert_equal "RelayObject", edge.fetch("node").fetch("__typename")
      assert_equal "RelayObjectEdge", edge["__typename"]
    end

    it "authorizes _after_ resolving lazy objects" do
      query = <<-GRAPHQL
      {
        a: unauthorizedLazyBox(value: "a") { value }
        b: unauthorizedLazyBox(value: "b") { value }
      }
      GRAPHQL

      unauthorized_res = auth_execute(query)
      assert_nil unauthorized_res["data"].fetch("a")
      assert_equal "b", unauthorized_res["data"]["b"]["value"]
    end

    it "authorizes items in a list" do
      query = <<-GRAPHQL
      {
        unauthorizedListItems { __typename }
      }
      GRAPHQL

      unauthorized_res = auth_execute(query, context: { hide: true })

      assert_nil unauthorized_res["data"]["unauthorizedListItems"]
      authorized_res = auth_execute(query, context: { hide: false })
      assert_equal 2, authorized_res["data"]["unauthorizedListItems"].size
    end

    it "syncs lazy objects from authorized? checks" do
      query = <<-GRAPHQL
      {
        a: unauthorizedLazyCheckBox(value: "a") { value }
        b: unauthorizedLazyCheckBox(value: "b") { value }
      }
      GRAPHQL

      unauthorized_res = auth_execute(query)
      assert_nil unauthorized_res["data"].fetch("a")
      assert_equal "b", unauthorized_res["data"]["b"]["value"]
      # Also, the custom handler was called:
      assert_equal ["Unauthorized UnauthorizedCheckBox: a"], unauthorized_res["errors"].map { |e| e["message"] }
    end

    it "Works for lazy connections" do
      query = <<-GRAPHQL
      {
        lazyIntegers { edges { node { value } } }
      }
      GRAPHQL
      res = auth_execute(query)
      assert_equal [1,2,3], res["data"]["lazyIntegers"]["edges"].map { |e| e["node"]["value"] }
    end

    it "Works for eager connections" do
      query = <<-GRAPHQL
      {
        integers { edges { node { value } } }
      }
      GRAPHQL
      res = auth_execute(query)
      assert_equal [1,2,3], res["data"]["integers"]["edges"].map { |e| e["node"]["value"] }
    end

    it "filters out individual nodes by value" do
      query = <<-GRAPHQL
      {
        integers { edges { node { value } } }
      }
      GRAPHQL
      res = auth_execute(query, context: { exclude_integer: 1 })
      assert_equal [nil,2,3], res["data"]["integers"]["edges"].map { |e| e["node"] && e["node"]["value"] }
      assert_equal ["Unauthorized IntegerObject: 1"], res["errors"].map { |e| e["message"] }
    end

    it "works with lazy values / interfaces" do
      query = <<-GRAPHQL
      query($value: String!){
        unauthorizedInterface(value: $value) {
          ... on UnauthorizedCheckBox {
            value
          }
        }
      }
      GRAPHQL

      res = auth_execute(query, variables: { value: "a"})
      assert_nil res["data"]["unauthorizedInterface"]

      res2 = auth_execute(query, variables: { value: "b"})
      assert_equal "b", res2["data"]["unauthorizedInterface"]["value"]
    end

    it "works with lazy values / lists of interfaces" do
      query = <<-GRAPHQL
      {
        unauthorizedLazyListInterface {
          ... on UnauthorizedCheckBox {
            value
          }
        }
      }
      GRAPHQL

      res = auth_execute(query)
      # An error from two, values from the others
      assert_equal ["Unauthorized UnauthorizedCheckBox: a", "Unauthorized UnauthorizedCheckBox: a"], res["errors"].map { |e| e["message"] }
      assert_equal [{"value" => "z"}, {"value" => "z2"}, nil, nil], res["data"]["unauthorizedLazyListInterface"]
    end

    it "replaces objects from the unauthorized_object hook" do
      query = "{ replacedObject { replaced } }"
      res = auth_execute(query, context: { replace_me: true })
      assert_equal true, res["data"]["replacedObject"]["replaced"]

      res = auth_execute(query, context: { replace_me: false })
      assert_equal false, res["data"]["replacedObject"]["replaced"]
    end
  end
end
