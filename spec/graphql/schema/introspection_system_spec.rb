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

    it "serves custom entry points"  do
      res = Jazz::Schema.execute("{ __classname }", root_value: Set.new)
      assert_equal "Set", res["data"]["__classname"]
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
  end
end
