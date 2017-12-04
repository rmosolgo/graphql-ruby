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

    it "doesn't affect other schemas" do
      res = Dummy::Schema.execute("{ __schema { isJazzy } }")
      assert_nil res["data"]
      # it's a validation error
      assert_equal 1, res["errors"].length
    end
  end
end
