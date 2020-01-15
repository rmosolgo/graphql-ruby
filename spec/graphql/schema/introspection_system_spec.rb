# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::IntrospectionSystem do
  describe "custom introspection" do
    it "serves custom fields on types" do
      res = Jazz::Schema.execute("{ __schema { isJazzy } }")
      assert_equal true, res["data"]["__schema"]["isJazzy"]
    end

    it "serves overridden fields on types" do
      res = Jazz::Schema.execute(%|{ __type(name: "Ensemble") { name } }|)
      assert_equal "ENSEMBLE", res["data"]["__type"]["name"]
    end

    it "serves custom entry points" do
      res = Jazz::Schema.execute("{ __classname }", root_value: Set.new)
      assert_equal "Set", res["data"]["__classname"]
    end

    it "calls authorization methods of those types" do
      res = Jazz::Schema.execute(%|{ __type(name: "Ensemble") { name } }|)
      assert_equal "ENSEMBLE", res["data"]["__type"]["name"]

      unauth_res = Jazz::Schema.execute(%|{ __type(name: "Ensemble") { name } }|, context: { cant_introspect: true })
      assert_nil unauth_res["data"].fetch("__type")
      assert_equal ["You're not allowed to introspect here"], unauth_res["errors"].map { |e| e["message"] }
    end

    it "serves custom dynamic fields" do
      res = Jazz::Schema.execute("{ nowPlaying { __typename __typenameLength __astNodeClass } }")
      assert_equal "Ensemble", res["data"]["nowPlaying"]["__typename"]
      assert_equal 8, res["data"]["nowPlaying"]["__typenameLength"]
      assert_equal "GraphQL::Language::Nodes::Field", res["data"]["nowPlaying"]["__astNodeClass"]
    end

    it "doesn't affect other schemas" do
      res = Dummy::Schema.execute("{ __schema { isJazzy } }")
      assert_equal 1, res["errors"].length

      res = Dummy::Schema.execute("{ __classname }", root_value: Set.new)
      assert_equal 1, res["errors"].length

      res = Dummy::Schema.execute("{ ensembles { __typenameLength } }")
      assert_equal 1, res["errors"].length
    end

    it "runs the introspection query" do
      res = Jazz::Schema.execute(GraphQL::Introspection::INTROSPECTION_QUERY)
      assert res
      query_type = res["data"]["__schema"]["types"].find { |t| t["name"] == "QUERY" }
      ensembles_field = query_type["fields"].find { |f| f["name"] == "ensembles" }
      assert_equal [], ensembles_field["args"]
    end

    it "doesn't include invisible union types based on context" do
      context = { hide_ensemble: true }
      res = Jazz::Schema.execute('{ __type(name: "PerformingAct") { possibleTypes { name } } }', context: context)

      assert_equal 1, res["data"]["__type"]["possibleTypes"].length
      assert_equal "MUSICIAN", res["data"]["__type"]["possibleTypes"].first["name"]
    end

    it "does not include hidden interfaces based on context" do
      context = { private: false }
      res = Jazz::Schema.execute('{ __type(name: "Ensemble") { interfaces { name } } }', context: context)

      assert res["data"]["__type"]["interfaces"].none? { |i| i["name"] == "PRIVATENAMEENTITY" }
    end

    it "includes hidden interfaces based on the context" do
      context = { private: true }
      res = Jazz::Schema.execute('{ __type(name: "Ensemble") { interfaces { name } } }', context: context)

      assert res["data"]["__type"]["interfaces"].any? { |i| i["name"] == "PRIVATENAMEENTITY" }
    end

    focus
    it "does not include fields from hidden  interfaces based on the context" do
      context = { private: false }
      res = Jazz::Schema.execute('{ __type(name: "Ensemble") { fields { name } } }', context: context)

      assert res["data"]["__type"]["fields"].none? { |i| i["name"] == "privateName" }
    end

    focus
    it "includes fields from interfaces based on the context" do
      context = { private: true }
      res = Jazz::Schema.execute('{ __type(name: "Ensemble") { fields { name } } }', context: context)

      assert res["data"]["__type"]["fields"].any? { |i| i["name"] == "privateName" }
    end
  end

  describe "#disable_introspection_entry_points" do
    let(:schema) { Jazz::Schema }

    it "allows entry point introspection by default" do
      res = schema.execute("{ __schema { types { name } } }")
      assert res

      types = res["data"]["__schema"]["types"]
      refute_empty types
    end

    describe "when entry points introspection is disabled" do
      let(:schema) { Jazz::SchemaWithoutIntrospection }

      it "returns error" do
        res = schema.execute("{ __schema { types { name } } }")
        assert res

        assert_nil res["data"]
        assert_equal ["Field '__schema' doesn't exist on type 'Query'"], res["errors"].map { |e| e["message"] }
      end
    end
  end
end
