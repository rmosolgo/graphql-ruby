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

      underscored_field = GraphQL::Schema::Field.new(:underscored_field, String, null: false, camelize: false, owner: nil) do
        argument :underscored_arg, String, required: true, camelize: false
      end

      assert_equal 'underscored_field', underscored_field.to_graphql.name
      arg_name, arg_defn = underscored_field.to_graphql.arguments.first
      assert_equal 'underscored_arg', arg_name
      assert_equal 'underscored_arg', arg_defn.name
    end

    it "exposes the method override" do
      object = Class.new(Jazz::BaseObject) do
        field :t, String, method: :tt, null: true
      end
      assert_equal :tt, object.fields["t"].method_sym
      assert_equal "tt", object.fields["t"].method_str
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

    it "accepts anonymous classes as type" do
      type = Class.new(GraphQL::Schema::Object) do
        graphql_name 'MyType'
      end
      field = GraphQL::Schema::Field.new(:my_field, type, owner: nil, null: true)
      assert_equal type.to_graphql, field.to_graphql.type
    end

    describe "extras" do
      it "can get errors, which adds path" do
        query_str = <<-GRAPHQL
        query {
          find(id: "Musician/Herbie Hancock") {
            ... on Musician {
              addError
            }
          }
        }
        GRAPHQL

        res = Jazz::Schema.execute(query_str)
        err = res["errors"].first
        assert_equal "this has a path", err["message"]
        assert_equal ["find", "addError"], err["path"]
        assert_equal [{"line"=>4, "column"=>15}], err["locations"]
      end
    end

    it "is the #owner of its arguments" do
      field = Jazz::Query.fields["find"]
      argument = field.arguments["id"]
      assert_equal field, argument.owner
    end

    it "has a reference to the object that owns it with #owner" do
      assert_equal Jazz::Query, field.owner
    end

    describe "type" do
      it "tells the return type" do
        assert_equal "[String!]!", field.type.graphql_definition.to_s
      end
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

  describe "build type errors" do
    it "includes the full name" do
      thing = Class.new(GraphQL::Schema::Object) do
        graphql_name "Thing"
        # `Set` is a class but not a GraphQL type
        field :stuff, Set, null: false
      end

      err = assert_raises ArgumentError do
        thing.fields["stuff"].to_graphql.type
      end

      assert_includes err.message, "Thing.stuff"
    end
  end
end
