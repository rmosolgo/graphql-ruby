# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Field do
  describe "graphql definition" do
    let(:object_class) { Jazz::Query }
    let(:field) { object_class.fields["inspect_input"] }

    it "uses the argument class" do
      arg_defn = field.graphql_definition.arguments.values.first
      assert_equal :ok, arg_defn.metadata[:custom]
    end

    it "camelizes the field name, unless camelize: false" do
      assert_equal 'inspectInput', field.graphql_definition.name

      underscored_field = GraphQL::Schema::Field.new(:underscored_field, String, null: false, camelize: false) do
        argument :underscored_arg, String, required: true, camelize: false
      end

      assert_equal 'underscored_field', underscored_field.to_graphql.name
      arg_name, arg_defn = underscored_field.to_graphql.arguments.first
      assert_equal 'underscored_arg', arg_name
      assert_equal 'underscored_arg', arg_defn.name
    end

    it "exposes the method override" do
      assert_nil field.method
      object = Class.new(Jazz::BaseObject) do
        field :t, String, method: :tt, null: true
      end
      assert_equal :tt, object.fields["t"].method
    end

    it "accepts a block for definition" do
      object = Class.new(Jazz::BaseObject) do
        graphql_name "JustAName"

        field :test, String, null: true do
          argument :test, String, required: true
          description "A Description."
        end
      end.to_graphql

      assert_equal "test", object.fields["test"].arguments["test"].name
      assert_equal "A Description.", object.fields["test"].description
    end
  end
end
