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
      argument :top_secret, Boolean, required: true
      locations(FIELD_DEFINITION, ARGUMENT_DEFINITION)
    end

    class Thing < GraphQL::Schema::Object
      field :name, String, null: false do
        directive Secret, top_secret: true
        argument :nickname, Boolean, required: false do
          directive Secret, top_secret: false
        end
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
    err = assert_raises ArgumentError do
      GraphQL::Schema::Field.from_options(
        name: :something,
        type: String,
        null: false,
        owner: DirectiveTest::Thing,
        directives: { DirectiveTest::Secret => {} }
      )
    end

    assert_equal "@secret.topSecret is required, but no value was given", err.message

    err2 = assert_raises ArgumentError do
      GraphQL::Schema::Field.from_options(
        name: :something,
        type: String,
        null: false,
        owner: DirectiveTest::Thing,
        directives: { DirectiveTest::Secret => { top_secret: 12.5 } }
      )
    end

    assert_equal "@secret.topSecret is required, but no value was given", err2.message
  end


  module RuntimeDirectiveTest
    class CountFields < GraphQL::Schema::Directive
      locations(FIELD, FRAGMENT_SPREAD, INLINE_FRAGMENT)

      def self.resolve(obj, args, ctx)
        path = ctx[:current_path]
        result = yield

        result = ctx.schema.sync_lazy(result)

        ctx[:count_fields] ||= Hash.new { |h, k| h[k] = [] }
        field_count = result.is_a?(Hash) ? result.size : 1
        p [path, field_count, result]
        ctx[:count_fields][path] << field_count
        nil # this does nothing
      end
    end

    class Thing < GraphQL::Schema::Object
      field :name, String, null: false

      def name
        -> { object[:name] }
      end

      field :thing, Thing, null: false

      def thing
        { name: "thing" }
      end
    end

    class Query < GraphQL::Schema::Object
      field :thing, Thing, null: false

      def thing
        { name: "thing" }
      end

      field :lazy_thing, Thing, null: false
      def lazy_thing
        -> { thing }
      end

      field :dataloaded_thing, Thing, null: false
      def dataloaded_thing
        dataloader.with(ThingSource).load("something")
      end
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
    focus
    it "works with fragment spreads, inline fragments, and fields" do
      query_str = <<-GRAPHQL
      {
        thing {
          cn: name @countFields
        }
        ... @countFields {
          t2: thing { t2n: name }
          t3: thing { t3n: name }
        }
        lazyThing {
          ...Thing @countFields
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
        "thing" => {
          "cn" => "thing",
        },
        "lazyThing" => {
          "n1" => "thing",
          "n2" => "thing",
          "n3" => "thing",
        },
        "t2"=>{"t2n"=>"thing"},
        "t3"=>{"t3n"=>"thing"},
      }
      assert_equal expected_data, res["data"]

      expected_counts = {
        ["thing", "cn"] => [1],
        [] => [2],
        ["thing"] => [3],
      }
      assert_equal expected_counts, res.context[:count_fields]
    end
  end
end
