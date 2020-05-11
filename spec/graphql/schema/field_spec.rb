# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Field do
  describe "graphql definition" do
    let(:object_class) { Jazz::Query }
    let(:field) { object_class.fields["inspectInput"] }

    describe "path" do
      it "is the object/interface and field name" do
        assert_equal "Query.inspectInput", field.path
        assert_equal "GloballyIdentifiable.id", Jazz::GloballyIdentifiableType.fields["id"].path
      end
    end

    it "uses the argument class" do
      arg_defn = field.graphql_definition.arguments.values.first
      assert_equal :ok, arg_defn.metadata[:custom]
    end

    it "can add argument directly with add_argument" do
      argument = Jazz::Query.fields["instruments"].arguments["family"]

      field.add_argument(argument)

      assert_equal "family", field.arguments["family"].name
      assert_equal Jazz::Family, field.arguments["family"].type
    end

    it "attaches itself to its graphql_definition as type_class" do
      assert_equal field, field.graphql_definition.metadata[:type_class]
    end

    it "camelizes the field name, unless camelize: false" do
      assert_equal 'inspectInput', field.graphql_definition.name
      assert_equal 'inspectInput', field.name

      underscored_field = GraphQL::Schema::Field.from_options(:underscored_field, String, null: false, camelize: false, owner: nil) do
        argument :underscored_arg, String, required: true, camelize: false
      end

      assert_equal 'underscored_field', underscored_field.to_graphql.name
      arg_name, arg_defn = underscored_field.to_graphql.arguments.first
      assert_equal 'underscored_arg', arg_name
      assert_equal 'underscored_arg', arg_defn.name
    end

    it "works with arbitrary hash keys" do
      result = Jazz::Schema.execute "{ complexHashKey }", root_value: { :'foo bar/fizz-buzz' => "OK!"}
      hash_val = result["data"]["complexHashKey"]
      assert_equal "OK!", hash_val, "It looked up the hash key"
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

    it "accepts a block for defintion and yields the field if the block has an arity of one" do
      object = Class.new(Jazz::BaseObject) do
        graphql_name "JustAName"

        field :test, String, null: true do |field|
          field.argument :test, String, required: true
          field.description "A Description."
        end
      end.to_graphql

      assert_equal "test", object.fields["test"].arguments["test"].name
      assert_equal "A Description.", object.fields["test"].description
    end

    it "accepts anonymous classes as type" do
      type = Class.new(GraphQL::Schema::Object) do
        graphql_name 'MyType'
      end
      field = GraphQL::Schema::Field.from_options(:my_field, type, owner: nil, null: true)
      assert_equal type.to_graphql, field.to_graphql.type
    end

    describe "introspection?" do
      it "returns false on regular fields" do
        assert_equal false, field.introspection?
      end

      it "returns true on predefined introspection fields" do
        assert_equal true, GraphQL::Schema.types['__Type'].fields.values.first.introspection?
      end
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

      it "can get methods from the field instance" do
        query_str = <<-GRAPHQL
        {
          upcaseCheck1
          upcaseCheck2
          upcaseCheck3
          upcaseCheck4
        }
        GRAPHQL
        res = Jazz::Schema.execute(query_str)
        assert_equal "nil", res["data"].fetch("upcaseCheck1")
        assert_equal "false", res["data"]["upcaseCheck2"]
        assert_equal "TRUE", res["data"]["upcaseCheck3"]
        assert_equal "\"WHY NOT?\"", res["data"]["upcaseCheck4"]
      end

      it "can be read via #extras" do
        field = Jazz::Musician.fields["addError"]
        assert_equal [:execution_errors], field.extras
      end

      it "can be added by passing an array of symbols to #extras" do
        object = Class.new(Jazz::BaseObject) do
          graphql_name "JustAName"

          field :test, String, null: true, extras: [:lookahead]
        end

        field = object.fields['test']

        field.extras([:ast_node])
        assert_equal [:lookahead, :ast_node], field.extras
      end

      describe "argument_details" do
        class ArgumentDetailsSchema < GraphQL::Schema
          class Query < GraphQL::Schema::Object
            field :argument_details, [String], null: false, extras: [:argument_details] do
              argument :arg1, Int, required: false
              argument :arg2, Int, required: false, default_value: 2
            end

            def argument_details(argument_details:, arg1: nil, arg2:)
              [
                argument_details.class.name,
                argument_details.argument_values.values.first.class.name,
                # `.keyword_arguments` includes extras:
                argument_details.keyword_arguments.keys.join("|"),
                # `.argument_values` includes only defined GraphQL arguments:
                argument_details.argument_values.keys.join("|"),
                argument_details.argument_values[:arg2].default_used?.inspect
              ]
            end
          end

          query(Query)
          use(GraphQL::Execution::Interpreter)
          use(GraphQL::Analysis::AST)
        end

        it "provides metadata about arguments" do
          res = ArgumentDetailsSchema.execute("{ argumentDetails }")
          expected_strs = [
            "GraphQL::Execution::Interpreter::Arguments",
            "GraphQL::Execution::Interpreter::ArgumentValue",
            "arg2|argument_details",
            "arg2",
            "true",
          ]
          assert_equal expected_strs, res["data"]["argumentDetails"]
        end
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

      it "returns the type class" do
        field = Jazz::Query.fields["nowPlaying"]
        assert_equal Jazz::PerformingAct, field.type.of_type
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
        thing.fields["stuff"].type
      end

      assert_includes err.message, "Thing.stuff"
      assert_includes err.message, "Unexpected class/module"
    end

    it "makes a suggestion when the type is false" do
      err = assert_raises ArgumentError do
        Class.new(GraphQL::Schema::Object) do
          graphql_name "Thing"
          # False might come from an invalid `!`
          field :stuff, false, null: false
        end
      end

      assert_includes err.message, "Thing.stuff"
      assert_includes err.message, "Received `false` instead of a type, maybe a `!` should be replaced with `null: true` (for fields) or `required: true` (for arguments)"
    end

    it "makes a suggestion when the type is a GraphQL::Field" do
      err = assert_raises ArgumentError do
        Class.new(GraphQL::Schema::Object) do
          graphql_name "Thing"
          # Previously, field was a valid second argument
          field :stuff, GraphQL::Relay::Node.field, null: false
        end
      end

      assert_includes err.message, "use the `field:` keyword for this instead"
    end
  end

  describe "mutation" do
    it "passes when not including extra arguments" do
      mutation_class = Class.new(GraphQL::Schema::Mutation) do
        graphql_name "Thing"
        field :stuff, String, null: false
      end

      obj = Class.new(GraphQL::Schema::Object) do
        field(:my_field, mutation: mutation_class, null: true)
      end
      assert_equal obj.fields["myField"].mutation, mutation_class
    end
  end

  describe '#deprecation_reason' do
    it "reads and writes" do
      object_class = Class.new(GraphQL::Schema::Object) do
        graphql_name "Thing"
        field :stuff, String, null: false, deprecation_reason: "Broken"
      end
      field = object_class.fields["stuff"]
      assert_equal "Broken", field.deprecation_reason
      field.deprecation_reason += "!!"
      assert_equal "Broken!!", field.deprecation_reason
    end
  end

  describe "#original_name" do
    it "is exactly the same as the passed in name" do
      field = GraphQL::Schema::Field.from_options(
        :my_field,
        String,
        null: false,
        camelize: true
      )

      assert_equal :my_field, field.original_name
    end
  end

  describe "generated default" do
    class GeneratedDefaultTestSchema < GraphQL::Schema
      class BaseField < GraphQL::Schema::Field
        def resolve_field(obj, args, ctx)
          resolve(obj, args, ctx)
        end
      end

      class Company < GraphQL::Schema::Object
        field :id, ID, null: false
      end

      class Query < GraphQL::Schema::Object
        field_class BaseField

        field :company, Company, null: true do
          argument :id, ID, required: true
        end

        def company(id:)
          OpenStruct.new(id: id)
        end
      end

      query(Query)
    end

    it "works" do
      res = GeneratedDefaultTestSchema.execute("{ company(id: \"1\") { id } }")
      assert_equal "1", res["data"]["company"]["id"]
    end
  end

  describe ".connection_extension" do
    class CustomConnectionExtension < GraphQL::Schema::Field::ConnectionExtension
      def apply
        super
        field.argument(:z, String, required: false)
      end
    end

    class CustomExtensionField < GraphQL::Schema::Field
      connection_extension(CustomConnectionExtension)
    end

    class CustomExtensionObject < GraphQL::Schema::Object
      field_class CustomExtensionField

      field :ints, GraphQL::Types::Int.connection_type, null: false, scope: false
    end

    it "can be customized" do
      field = CustomExtensionObject.fields["ints"]
      assert_equal [CustomConnectionExtension], field.extensions.map(&:class)
      assert_equal ["after", "before", "first", "last", "z"], field.arguments.keys.sort
    end

    it "can be inherited" do
      child_field_class = Class.new(CustomExtensionField)
      assert_equal CustomConnectionExtension, child_field_class.connection_extension
    end
  end

  describe "looking up hash keys with case" do
    class HashKeySchema < GraphQL::Schema
      class ResultType < GraphQL::Schema::Object
        field :lowercase, String, camelize: false, null: true
        field :Capital, String, camelize: false, null: true
        field :Other, String, camelize: true, null: true
        field :OtherCapital, String, camelize: false, null: true, hash_key: "OtherCapital"
      end

      class QueryType < GraphQL::Schema::Object
        field :search_results, ResultType, null: false
        def search_results
          {
            "lowercase" => "lowercase-works",
            "Capital" => "capital-camelize-false-works",
            "Other" => "capital-camelize-true-works",
            "OtherCapital" => "explicit-hash-key-works"
          }
        end
      end

      query(QueryType)
    end

    it "finds exact matches by hash key" do
      res = HashKeySchema.execute <<-GRAPHQL
      {
        searchResults {
          lowercase
          Capital
          Other
          OtherCapital
        }
      }
      GRAPHQL

      search_results = res["data"]["searchResults"]
      expected_result = {
        "lowercase" => "lowercase-works",
        "Capital" => "capital-camelize-false-works",
        "Other" => "capital-camelize-true-works",
        "OtherCapital" => "explicit-hash-key-works"
      }
      assert_equal expected_result, search_results
    end
  end
end
