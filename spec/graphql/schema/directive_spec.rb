# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Directive do
  class MultiWord < GraphQL::Schema::Directive
  end

  it "uses a downcased class name" do
    assert_equal "multiWord", MultiWord.graphql_name
  end

  module DirectiveTest
    class Secret < GraphQL::Schema::Directive
      argument :top_secret, Boolean
      class PermissionRule < GraphQL::Schema::InputObject
        class Permission < GraphQL::Schema::Enum
          value :READ
          value :WRITE
        end
        argument :team, String
        argument :permission, Permission
      end
      argument :permission_rules, [PermissionRule], required: false
      locations(FIELD_DEFINITION, ARGUMENT_DEFINITION)
    end

    class Thing < GraphQL::Schema::Object
      field :name, String, null: false do
        directive Secret, top_secret: true
        argument :nickname, Boolean, required: false do
          directive Secret, top_secret: false
        end
      end

      field :other_info, String do
        directive Secret, top_secret: false, permission_rules: [
          { team: "admins", permission: "WRITE" },
          { team: "others", permission: "READ"},
        ]
      end
    end
  end

  it "can be added to schema definitions" do
    field = DirectiveTest::Thing.fields.values.first

    assert_equal [DirectiveTest::Secret], field.directives.map(&:class)
    assert_equal [field], field.directives.map(&:owner)
    assert_equal [true], field.directives.map{ |d| d.arguments[:top_secret] }

    argument = field.arguments.values.first
    assert_equal [DirectiveTest::Secret], argument.directives.map(&:class)
    assert_equal [argument], argument.directives.map(&:owner)
    assert_equal [false], argument.directives.map{ |d| d.arguments[:top_secret] }

    other_field = DirectiveTest::Thing.fields.values.last
    other_field_dir = other_field.directives.first
    perm_roles = other_field_dir.arguments[:permission_rules]
    assert_equal Array.new(2, DirectiveTest::Secret::PermissionRule), perm_roles.map(&:class)
    assert_equal ["WRITE", "READ"], perm_roles.map(&:permission)
  end

  it "raises an error when added to the wrong thing" do
    err = assert_raises ArgumentError do
      Class.new(GraphQL::Schema::Object) do
        graphql_name "Stuff"
        directive DirectiveTest::Secret
      end
    end

    expected_message = "Directive `@secret` can't be attached to Stuff because OBJECT isn't included in its locations (FIELD_DEFINITION, ARGUMENT_DEFINITION).

Use `locations(OBJECT)` to update this directive's definition, or remove it from Stuff.
"

    assert_equal expected_message, err.message
  end

  it "validates arguments" do
    err = assert_raises GraphQL::Schema::Directive::InvalidArgumentError do
      GraphQL::Schema::Field.from_options(
        name: :something,
        type: String,
        null: false,
        owner: DirectiveTest::Thing,
        directives: { DirectiveTest::Secret => {} }
      )
    end

    assert_equal "@secret.topSecret on Thing.something is invalid (nil): Expected value to not be null", err.message
  end

  describe 'repeatable directives' do
    module RepeatDirectiveTest
      class Secret < GraphQL::Schema::Directive
        argument :secret, String
        locations OBJECT, INTERFACE
        repeatable true
      end

      class OtherSecret < GraphQL::Schema::Directive
        argument :secret, String
        locations OBJECT, INTERFACE
        repeatable false
      end

      class Thing < GraphQL::Schema::Object
        directive(Secret, secret: "my secret")
        directive(Secret, secret: "my second secret")

        directive(OtherSecret, secret: "other secret")
        directive(OtherSecret, secret: "second other secret")
      end
    end

    it "allows repeatable directives twice" do
      directives = RepeatDirectiveTest::Thing.directives
      secret_directives = directives.select{ |x| x.is_a?(RepeatDirectiveTest::Secret) }

      assert_equal 2, secret_directives.size
      assert_equal ["my secret", "my second secret"], secret_directives.map{ |d| d.arguments[:secret] }
    end

    it "overwrites non-repeatable directives" do
      directives = RepeatDirectiveTest::Thing.directives
      other_directives = directives.select{ |x| x.is_a?(RepeatDirectiveTest::OtherSecret) }

      assert_equal 1, other_directives.size
      assert_equal ["second other secret"], other_directives.map{ |d| d.arguments[:secret] }
    end
  end

  module RuntimeDirectiveTest
    class CountFields < GraphQL::Schema::Directive
      locations(FIELD, FRAGMENT_SPREAD, INLINE_FRAGMENT)

      def self.resolve(obj, args, ctx)
        path = ctx[:current_path]
        result = nil
        ctx.dataloader.run_isolated do
          result = yield
          ctx.dataloader.run
        end

        ctx[:count_fields] ||= Hash.new { |h, k| h[k] = [] }
        field_count = result.respond_to?(:graphql_result_data) ? result.graphql_result_data.size : 1
        ctx[:count_fields][path] << field_count
        nil # this does nothing
      end
    end

    class Thing < GraphQL::Schema::Object
      field :name, String, null: false
    end

    module HasThings
      include GraphQL::Schema::Interface
      field :thing, Thing, null: false, extras: [:ast_node]

      def thing(ast_node:)
        context[:name_resolved_count] ||= 0
        context[:name_resolved_count] += 1
        { name: ast_node.alias || ast_node.name }
      end

      field :lazy_thing, Thing, null: false, extras: [:ast_node]
      def lazy_thing(ast_node:)
        -> { thing(ast_node: ast_node) }
      end

      field :dataloaded_thing, Thing, null: false, extras: [:ast_node]
      def dataloaded_thing(ast_node:)
        dataloader.with(ThingSource).load(ast_node.alias || ast_node.name)
      end

      field :lazy_things, [Thing], extras: [:ast_node]
      def lazy_things(ast_node:)
        -> { [thing(ast_node: ast_node), thing(ast_node: ast_node)]}
      end
    end

    Thing.implements(HasThings)

    class Query < GraphQL::Schema::Object
      implements HasThings
    end

    class ThingSource < GraphQL::Dataloader::Source
      def fetch(names)
        names.map { |n| { name: n } }
      end
    end

    class Schema < GraphQL::Schema
      query(Query)
      directive(CountFields)
      lazy_resolve(Proc, :call)
      use GraphQL::Dataloader
    end
  end

  describe "runtime directives" do
    it "works with fragment spreads, inline fragments, and fields" do
      query_str = <<-GRAPHQL
      {
        t1: dataloadedThing {
          t1n: name @countFields
        }
        ... @countFields {
          t2: thing { t2n: name }
          t3: thing { t3n: name }
        }

        t3: thing { t3n: name }

        t4: lazyThing {
          ...Thing @countFields
        }

        t5: thing {
          n5: name
          t5d: dataloadedThing {
            t5dl: lazyThing { t5dln: name @countFields }
          }
        }
      }

      fragment Thing on Thing {
        n1: name
        n2: name
        n3: name
      }
      GRAPHQL

      res = RuntimeDirectiveTest::Schema.execute(query_str)
      expected_data = {
        "t1" => {
          "t1n" => "t1",
        },
        "t2"=>{"t2n"=>"t2"},
        "t3"=>{"t3n"=>"t3"},
        "t4" => {
          "n1" => "t4",
          "n2" => "t4",
          "n3" => "t4",
        },
        "t5"=>{"n5"=>"t5", "t5d"=>{"t5dl"=>{"t5dln"=>"t5dl"}}},
      }
      assert_graphql_equal expected_data, res["data"]

      expected_counts = {
        ["t1", "t1n"] => [1],
        [] => [2],
        ["t4"] => [3],
        ["t5", "t5d", "t5dl", "t5dln"] => [1],
      }
      assert_equal expected_counts, res.context[:count_fields]
    end

    it "runs things twice when they're in with-directive and without-directive parts of the query" do
      query_str = <<-GRAPHQL
      {
        t1: thing { name }      # name_resolved_count = 1
        t2: thing { name }      # name_resolved_count = 2

        ... @countFields {
          t1: thing { name }    # name_resolved_count = 3
          t3: thing { name }    # name_resolved_count = 4
        }

        t3: thing { name }      # name_resolved_count = 5
        ... {
          t2: thing { name @countFields } # This is merged back into `t2` above
        }
      }
      GRAPHQL
      res = RuntimeDirectiveTest::Schema.execute(query_str)
      expected_data = { "t1" => { "name" => "t1"}, "t2" => { "name" => "t2" }, "t3" => { "name" => "t3" } }
      assert_graphql_equal expected_data, res["data"]

      expected_counts = {
        [] => [2],
        ["t2", "name"] => [1],
       }
      assert_equal expected_counts, res.context[:count_fields]
      assert_equal 5, res.context[:name_resolved_count]
    end

    it "works with backtrace: true and lazy lists" do
      query_str = "
      {
        lazyThings @countFields {
          name
        }
      }
      "
      res = RuntimeDirectiveTest::Schema.execute(query_str, context: { backtrace: true })
      assert_equal 2, res["data"]["lazyThings"].size
    end
  end

  describe "raising an error from an argument" do
    class DirectiveErrorSchema < GraphQL::Schema
      class MyDirective < GraphQL::Schema::Directive
        locations GraphQL::Schema::Directive::QUERY, GraphQL::Schema::Directive::FIELD

        argument :input, String, prepare: ->(input, ctx) {
          raise GraphQL::ExecutionError, "invalid argument"
        }
      end

      class QueryType < GraphQL::Schema::Object
        field :hello, String, null: false

        def hello
          "Hello World!"
        end
      end
      query QueryType

      directive MyDirective
    end

    it "halts execution and adds an error to the error key" do
      result = DirectiveErrorSchema.execute(<<-GQL)
      query @myDirective(input: "hi") {
        hello
      }
      GQL

      assert_equal({}, result["data"])
      assert_equal ["invalid argument"], result["errors"].map { |e| e["message"] }
      assert_equal [[{"line"=>1, "column"=>13}]], result["errors"].map { |e| e["locations"] }

      result2 = DirectiveErrorSchema.execute(<<-GQL)
      query {
        hello
        hello2: hello @myDirective(input: "hi")
      }
      GQL

      assert_equal({ "hello" => "Hello World!" }, result2["data"])
      assert_equal ["invalid argument"], result2["errors"].map { |e| e["message"] }
      assert_equal [[{"line"=>3, "column"=>23}]], result2["errors"].map { |e| e["locations"] }
    end
  end

  describe ".resolve_each" do
    class ResolveEachSchema < GraphQL::Schema
      class FilterByIndex < GraphQL::Schema::Directive
        locations FIELD
        argument :select, String

        def self.resolve_each(object, args, context)
          if context[:current_path].last.public_send(args[:select])
            yield
          else
            # Don't send a value
          end
        end

        def self.resolve(obj, args, ctx)
          value = yield
          value.values.compact!
          value
        end
      end

      class Query < GraphQL::Schema::Object
        field :numbers, [Integer]
        def numbers
          [0,1,2,3,4,5]
        end
      end

      query(Query)
      directive(FilterByIndex)
    end

    it "is called for each item in a list during enumeration" do
      res = ResolveEachSchema.execute("{ numbers @filterByIndex(select: \"even?\")}")
      assert_equal [0,2,4], res["data"]["numbers"]
      res = ResolveEachSchema.execute("{ numbers @filterByIndex(select: \"odd?\")}")
      assert_equal [1,3,5], res["data"]["numbers"]
    end
  end

  it "parses repeated directives" do
    schema_sdl = <<~EOS
      directive @tag(name: String!) repeatable on ARGUMENT_DEFINITION | ENUM | ENUM_VALUE | FIELD_DEFINITION | INPUT_FIELD_DEFINITION | INPUT_OBJECT | INTERFACE | OBJECT | SCALAR | UNION

      type Query @tag(name: "t1") @tag(name: "t2") {
        something(
          arg: Boolean @tag(name: "t3") @tag(name: "t4")
        ): Stuff @tag(name: "t5") @tag(name: "t6")
      }

      enum Stuff {
        THING @tag(name: "t7") @tag(name: "t8")
      }
    EOS
    schema = GraphQL::Schema.from_definition(schema_sdl)
    query_type = schema.query
    assert_equal [["tag", { name: "t1" }], ["tag", { name: "t2" }]], query_type.directives.map { |dir| [dir.graphql_name, dir.arguments.to_h] }
    field = schema.get_field("Query", "something")
    arg = field.get_argument("arg")
    assert_equal [["tag", { name: "t3"}], ["tag", { name: "t4"}]], arg.directives.map { |dir| [dir.graphql_name, dir.arguments.to_h] }
    assert_equal [["tag", { name: "t5"}], ["tag", { name: "t6"}]], field.directives.map { |dir| [dir.graphql_name, dir.arguments.to_h] }

    enum_value = schema.get_type("Stuff").values["THING"]
    assert_equal [["tag", { name: "t7"}], ["tag", { name: "t8"}]], enum_value.directives.map { |dir| [dir.graphql_name, dir.arguments.to_h] }
  end

  describe "Custom validations on definition directives" do
    class DirectiveValidationSchema < GraphQL::Schema
      class SomeEnum < GraphQL::Schema::Enum
        value :VALUE_ONE, value: :v1
      end
      class ValidatedDirective < GraphQL::Schema::Directive
        locations OBJECT, FIELD
        argument :f, Float, required: false, validates: { numericality: { greater_than: 0 } }
        argument :s, String, required: false, validates: { format: { with: /^[a-z]{3}$/ } }
        argument :e, SomeEnum, required: false
        validates required: { one_of: [:f, :s]}
      end

      class Query < GraphQL::Schema::Object
        field :i, Int, fallback_value: 100
      end

      query(Query)
      directive(ValidatedDirective)
    end

    it "runs custom validation during execution" do
      f_err_res = DirectiveValidationSchema.execute("{ i @validatedDirective(f: -10) }")
      assert_equal [{"message" => "f must be greater than 0", "locations" => [{"line" => 1, "column" => 5}], "path" => ["i"]}], f_err_res["errors"]

      s_err_res = DirectiveValidationSchema.execute("{ i @validatedDirective(s: \"wnrn\") }")
      assert_equal [{"message" => "s is invalid", "locations" => [{"line" => 1, "column" => 5}], "path" => ["i"]}], s_err_res["errors"]

      f_s_err_res = DirectiveValidationSchema.execute("{ i @validatedDirective }")
      assert_equal [{"message" => "validatedDirective must include exactly one of the following arguments: f, s.", "locations" => [{"line" => 1, "column" => 5}], "path" => ["i"]}], f_s_err_res["errors"]
    end

    it "works with enums with symbol values" do
      e_err = DirectiveValidationSchema.execute("{ i @validatedDirective(e: VALUE_BLAH, f: 1.0) }")
      assert_equal ["Argument 'e' on Directive 'validatedDirective' has an invalid value (VALUE_BLAH). Expected type 'SomeEnum'."], e_err["errors"].map { |e| e["message"] }

      e_res = DirectiveValidationSchema.execute("{ i @validatedDirective(e: VALUE_ONE, f: 1.0) }")
      assert_equal 100, e_res["data"]["i"]

      obj_type = Class.new(GraphQL::Schema::Object)
      obj_type.graphql_name("EnumTestObj")
      directive_defn = DirectiveValidationSchema::ValidatedDirective
      obj_type.directive(directive_defn, f: 1, e: :v1)

      e_err = assert_raises GraphQL::Schema::Directive::InvalidArgumentError do
        obj_type.directive(directive_defn, f: 1, e: :blah)
      end
      assert_equal "@validatedDirective.e on EnumTestObj is invalid (:blah): Expected \"blah\" to be one of: VALUE_ONE", e_err.message
    end

    it "runs custom validation during definition" do
      obj_type = Class.new(GraphQL::Schema::Object)
      directive_defn = DirectiveValidationSchema::ValidatedDirective
      obj_type.directive(directive_defn, f: 1)
      f_err = assert_raises GraphQL::Schema::Validator::ValidationFailedError do
        obj_type.directive(directive_defn, f: -1)
      end
      assert_equal "f must be greater than 0", f_err.message

      obj_type.directive(directive_defn, s: "abc")
      s_err = assert_raises GraphQL::Schema::Validator::ValidationFailedError do
        obj_type.directive(directive_defn, s: "defg")
      end
      assert_equal "s is invalid", s_err.message

      required_err = assert_raises GraphQL::Schema::Validator::ValidationFailedError do
        obj_type.directive(directive_defn)
      end
      assert_equal "validatedDirective must include exactly one of the following arguments: f, s.", required_err.message
    end
  end

  describe "Validating schema directives" do
    def build_sdl(size:)
      <<~GRAPHQL
        directive @tshirt(size: Size!) on INTERFACE | OBJECT

        type MyType @tshirt(size: #{size}) {
          color: String
        }

        type Query {
          myType: MyType
        }

        enum Size {
          LARGE
          MEDIUM
          SMALL
        }
      GRAPHQL
    end

    it "Raises a nice error for invalid enum values" do
      valid_sdl = build_sdl(size: "MEDIUM")
      assert_equal valid_sdl, GraphQL::Schema.from_definition(valid_sdl).to_definition

      typo_sdl = build_sdl(size: "BLAH")
      err = assert_raises GraphQL::Schema::Directive::InvalidArgumentError do
        GraphQL::Schema.from_definition(typo_sdl)
      end
      expected_msg = '@tshirt.size on MyType is invalid ("BLAH"): Expected "BLAH" to be one of: LARGE, MEDIUM, SMALL'
      assert_equal expected_msg, err.message
    end
  end
end
