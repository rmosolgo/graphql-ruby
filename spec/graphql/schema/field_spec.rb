# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Field do
  describe "graphql definition" do
    let(:object_class) { Jazz::Query }
    let(:field) { object_class.fields.find { |f| f.name == "find" } }

    it "uses the argument class" do
      arg_defn = field.graphql_definition.arguments.values.first
      assert_equal :ok, arg_defn.metadata[:custom]
    end
  end
end
