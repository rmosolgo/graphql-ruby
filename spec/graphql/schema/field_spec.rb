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

    it "camelizes the field name" do
      assert_equal 'inspectInput', field.graphql_definition.name
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

    describe "complexity" do
      it "accepts a keyword argument" do
        object = Class.new(Jazz::BaseObject) do
          graphql_name "complexityKeyword"

          field :complexityTest, String, null: true, complexity: 25
        end.to_graphql

        assert_equal 25, object.fields["complexityTest"].complexity
      end

      it "accepts a proc in the definition block" do
        object = Class.new(Jazz::BaseObject) do
          graphql_name "complexityKeyword"

          field :complexityTest, String, null: true do
            complexity ->(_ctx, _args, _child_complexity) { 52 }
          end
        end.to_graphql

        assert_equal 52, object.fields["complexityTest"].complexity.call(nil, nil, nil)
      end

      it "accepts an integer in the definition block" do
        object = Class.new(Jazz::BaseObject) do
          graphql_name "complexityKeyword"

          field :complexityTest, String, null: true do
            complexity 38
          end
        end.to_graphql

        assert_equal 38, object.fields["complexityTest"].complexity
      end

      it 'fails if the complexity is not numeric and not a proc' do
        err = assert_raises(RuntimeError) do
          Class.new(Jazz::BaseObject) do
            graphql_name "complexityKeyword"

            field :complexityTest, String, null: true do
              complexity 'One hundred and eighty'
            end
          end.to_graphql
        end

        assert_match /^Invalid complexity:/, err.message
      end

      it 'fails if the proc does not accept 3 parameters' do
        err = assert_raises(RuntimeError) do
          Class.new(Jazz::BaseObject) do
            graphql_name "complexityKeyword"

            field :complexityTest, String, null: true do
              complexity ->(one, two) { 52 }
            end
          end.to_graphql
        end

        assert_match /^A complexity proc should always accept 3 parameters/, err.message
      end
    end
  end
end
