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

    describe "inspect" do
      it "includes the path and return type" do
        assert_equal "#<Jazz::BaseField Query.inspectInput(...): [String!]!>", field.inspect
      end
    end

    it "uses the argument class" do
      arg_defn = field.graphql_definition(silence_deprecation_warning: true).arguments.values.first
      assert_equal :ok, arg_defn.metadata[:custom]
    end

    it "can add argument directly with add_argument" do
      argument = Jazz::Query.fields["instruments"].arguments["family"]

      field.add_argument(argument)

      assert_equal "family", field.arguments["family"].name
      assert_equal Jazz::Family, field.arguments["family"].type
    end

    it "attaches itself to its graphql_definition as type_class" do
      assert_equal field, field.graphql_definition(silence_deprecation_warning: true).metadata[:type_class]
    end

    it "camelizes the field name, unless camelize: false" do
      assert_equal 'inspectInput', field.graphql_definition(silence_deprecation_warning: true).name
      assert_equal 'inspectInput', field.name

      underscored_field = GraphQL::Schema::Field.from_options(:underscored_field, String, null: false, camelize: false, owner: nil) do
        argument :underscored_arg, String, camelize: false
      end

      assert_equal 'underscored_field', underscored_field.deprecated_to_graphql.name
      arg_name, arg_defn = underscored_field.deprecated_to_graphql.arguments.first
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

        field :test, String do
          argument :test, String
          description "A Description."
        end
      end.deprecated_to_graphql

      assert_equal "test", object.fields["test"].arguments["test"].name
      assert_equal "A Description.", object.fields["test"].description
    end

    it "accepts a block for defintion and yields the field if the block has an arity of one" do
      object = Class.new(Jazz::BaseObject) do
        graphql_name "JustAName"

        field :test, String do |field|
          field.argument :test, String, required: true
          field.description "A Description."
        end
      end.deprecated_to_graphql

      assert_equal "test", object.fields["test"].arguments["test"].name
      assert_equal "A Description.", object.fields["test"].description
    end

    it "accepts anonymous classes as type" do
      type = Class.new(GraphQL::Schema::Object) do
        graphql_name 'MyType'
      end
      field = GraphQL::Schema::Field.from_options(:my_field, type, owner: nil, null: true)
      assert_equal type.deprecated_to_graphql, field.deprecated_to_graphql.type
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

          field :test, String, extras: [:lookahead]
        end

        field = object.fields['test']

        field.extras([:ast_node])
        assert_equal [:lookahead, :ast_node], field.extras
      end

      describe "ruby argument error" do
        class ArgumentErrorSchema < GraphQL::Schema
          class Query < GraphQL::Schema::Object

            def inspect
              "#<#{self.class}>"
            end

            field :f1, String do
              argument :something, Int, required: false
            end

            def f1
              "OK"
            end

            field :f2, String, resolver_method: :field_2 do
              argument :something, Int, required: false
            end

            def field_2(something_else: nil)
              "ALSO OK"
            end

            field :f3, String do
              argument :something, Int, required: false
            end

            def f3(always_missing:)
              "NEVER OK"
            end

            field :f4, String

            def f4(never_positional, ok_optional = :ok, *ok_rest)
              "NEVER OK"
            end

            field :f5, String do
              argument :something, Int, required: false
            end

            def f5(**ok_keyrest)
              "OK"
            end
          end
          query(Query)
        end

        it "raises a nice error when missing" do
          assert_equal "OK", ArgumentErrorSchema.execute("{ f1 }")["data"]["f1"]
          assert_equal "ALSO OK", ArgumentErrorSchema.execute("{ f2 }")["data"]["f2"]
          err = assert_raises GraphQL::Schema::Field::FieldImplementationFailed do
            ArgumentErrorSchema.execute("{ f1(something: 12) }")
          end
          assert_equal "Failed to call f1 on #<ArgumentErrorSchema::Query> because the Ruby method params were incompatible with the GraphQL arguments:

- `something: 12` was given by GraphQL but not defined in the Ruby method. Add `something:` to the method parameters.
", err.message

          assert_instance_of ArgumentError, err.cause

          err = assert_raises GraphQL::Schema::Field::FieldImplementationFailed do
            ArgumentErrorSchema.execute("{ f2(something: 12) }")
          end
          assert_equal "Failed to call field_2 on #<ArgumentErrorSchema::Query> because the Ruby method params were incompatible with the GraphQL arguments:

- `something: 12` was given by GraphQL but not defined in the Ruby method. Add `something:` to the method parameters.
", err.message


          err = assert_raises GraphQL::Schema::Field::FieldImplementationFailed do
            ArgumentErrorSchema.execute("{ f3(something: 1) }")
          end
          assert_equal "Failed to call f3 on #<ArgumentErrorSchema::Query> because the Ruby method params were incompatible with the GraphQL arguments:

- `something: 1` was given by GraphQL but not defined in the Ruby method. Add `something:` to the method parameters.
- `always_missing:` is required by Ruby, but not by GraphQL. Consider `always_missing: nil` instead, or making this argument required in GraphQL.
", err.message

          err = assert_raises GraphQL::Schema::Field::FieldImplementationFailed do
            ArgumentErrorSchema.execute("{ f4 }")
          end
          assert_equal "Failed to call f4 on #<ArgumentErrorSchema::Query> because the Ruby method params were incompatible with the GraphQL arguments:

- `never_positional` is required by Ruby, but GraphQL doesn't pass positional arguments. If it's meant to be a GraphQL argument, use `never_positional:` instead. Otherwise, remove it.
", err.message

          assert_equal "OK", ArgumentErrorSchema.execute("{ f5(something: 2) }")["data"]["f5"]
        end
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
        assert_equal "[String!]!", field.type.graphql_definition(silence_deprecation_warning: true).to_s
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

          field :complexityTest, String, complexity: 25
        end.deprecated_to_graphql

        assert_equal 25, object.fields["complexityTest"].complexity
      end

      it "accepts a proc in the definition block" do
        object = Class.new(Jazz::BaseObject) do
          graphql_name "complexityKeyword"

          field :complexityTest, String do
            complexity ->(_ctx, _args, _child_complexity) { 52 }
          end
        end.deprecated_to_graphql

        assert_equal 52, object.fields["complexityTest"].complexity.call(nil, nil, nil)
      end

      it "accepts an integer in the definition block" do
        object = Class.new(Jazz::BaseObject) do
          graphql_name "complexityKeyword"

          field :complexityTest, String do
            complexity 38
          end
        end.deprecated_to_graphql

        assert_equal 38, object.fields["complexityTest"].complexity
      end

      it 'fails if the complexity is not numeric and not a proc' do
        err = assert_raises(RuntimeError) do
          Class.new(Jazz::BaseObject) do
            graphql_name "complexityKeyword"

            field :complexityTest, String do
              complexity 'One hundred and eighty'
            end
          end.deprecated_to_graphql
        end

        assert_match /^Invalid complexity:/, err.message
      end

      it 'fails if the proc does not accept 3 parameters' do
        err = assert_raises(RuntimeError) do
          Class.new(Jazz::BaseObject) do
            graphql_name "complexityKeyword"

            field :complexityTest, String do
              complexity ->(one, two) { 52 }
            end
          end.deprecated_to_graphql
        end

        assert_match /^A complexity proc should always accept 3 parameters/, err.message
      end

      it 'fails if second argument is a mutation instead of a type' do
        mutation_class = Class.new(GraphQL::Schema::Mutation) do
          graphql_name "Thing"
          field :stuff, String, null: false
        end

        err = assert_raises(ArgumentError) do
          Class.new(Jazz::BaseObject) do
            graphql_name "complexityKeyword"

            field :complexityTest, mutation_class
          end
        end

        assert_match /^Use `field :complexityTest, mutation: Mutation, ...` to provide a mutation to this field instead/, err.message
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

      err = assert_raises GraphQL::Schema::Field::MissingReturnTypeError do
        thing.fields["stuff"].type
      end

      assert_includes err.message, "Thing.stuff"
      assert_includes err.message, "Unexpected class/module"
    end

    it "makes a suggestion when the type is false" do
      err = assert_raises GraphQL::Schema::Field::MissingReturnTypeError do
        Class.new(GraphQL::Schema::Object) do
          graphql_name "Thing"
          # False might come from an invalid `!`
          field :stuff, false, null: false
        end
      end

      assert_includes err.message, "Thing.stuff"
      assert_includes err.message, "Received `false` instead of a type, maybe a `!` should be replaced with `null: true` (for fields) or `required: true` (for arguments)"
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

        field :company, Company do
          argument :id, ID
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

  describe "retrieving nested hash keys using dig" do
    class DigSchema < GraphQL::Schema
      class PersonType < GraphQL::Schema::Object
        field :name, String, null: false
      end

      class MovieType < GraphQL::Schema::Object
        field :title, String, null: false, dig: [:title]
        field :stars, [PersonType], null: false, dig: ["credits", "stars"]
        field :metascore, Float, null: false, dig: [:meta, "metascore"]
        field :release_date, GraphQL::Types::ISO8601DateTime, null: false, dig: [:meta, :release_date]
        field :includes_wilhelm_scream, Boolean, null: false, dig: [:meta, "wilhelm_scream"]
        field :nullable_field, String, null: true, dig: [:this_should, :work_since, :dig_handles, :safe_expansion]
      end

      class QueryType < GraphQL::Schema::Object
        field :a_good_laugh, MovieType, null: false
        def a_good_laugh
          {
            :title => "Monty Python and the Holy Grail",
            :meta => {
              "metascore" => 91,
              :release_date => DateTime.new(1975, 5, 25, 0, 0, 0),
              "wilhelm_scream" => false
            },
            "credits" => {
              "stars" => [
                { :name => "Graham Chapman" },
                { :name => "John Cleese" }
              ]
            }
          }
        end
      end

      query(QueryType)
    end

    it "finds the expected data" do
      res = DigSchema.execute <<-GRAPHQL
      {
        aGoodLaugh {
          title
          includesWilhelmScream
          metascore
          nullableField
          releaseDate
          stars {
            name
          }
        }
      }
      GRAPHQL

      result = res["data"]["aGoodLaugh"]
      expected_result = {
        "title" => "Monty Python and the Holy Grail",
        "includesWilhelmScream" => false,
        "metascore" => 91.0,
        "nullableField" => nil,
        "releaseDate" => "1975-05-25T00:00:00+00:00",
        "stars" => [
          { "name" => "Graham Chapman" },
          { "name" => "John Cleese" }
        ]
      }
      assert_equal expected_result, result
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
