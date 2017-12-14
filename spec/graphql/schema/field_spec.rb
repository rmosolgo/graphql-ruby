# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Field do
  describe "graphql definition" do
    let(:object_class) { Jazz::Query }
    let(:field) { object_class.fields.find { |f| f.name == "inspect_input" } }

    it "uses the argument class" do
      arg_defn = field.graphql_definition.arguments.values.first
      assert_equal :ok, arg_defn.metadata[:custom]
    end

    it "camelizes the field name" do
      assert_equal 'inspectInput', field.graphql_definition.name
    end

    describe "description in block" do
      it "will raise if description is defined both in the argument and in the block" do
        assert_raises RuntimeError, "You're overriding the description of shouldRaise in the provided block!" do
          Class.new(Jazz::BaseObject) do
            graphql_name "JustAName"

            field :should_raise, Jazz::Key, "this should not raise", null: true do
              description "This should raise"
            end
          end.to_graphql
        end
      end
    end
  end
end
