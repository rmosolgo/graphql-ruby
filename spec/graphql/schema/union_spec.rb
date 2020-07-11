# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Union do
  let(:union) { Jazz::PerformingAct }

  describe ".path" do
    it "is the name" do
      assert_equal "PerformingAct", union.path
    end
  end

  describe "type info" do
    it "has some" do
      assert_equal 2, union.possible_types.size
    end
  end

  describe "filter_possible_types" do
    it "filters types" do
      assert_equal [Jazz::Musician], union.possible_types(context: { hide_ensemble: true })
    end
  end

  describe ".to_graphql" do
    it "creates a UnionType" do
      union = Class.new(GraphQL::Schema::Union) do
        possible_types Jazz::Musician, Jazz::Ensemble

        def self.name
          "MyUnion"
        end
      end
      union_type = union.to_graphql
      assert_equal "MyUnion", union_type.name
      assert_equal [Jazz::Musician.to_graphql, Jazz::Ensemble.to_graphql], union_type.possible_types
      assert_nil union_type.resolve_type_proc
    end

    it "can specify a resolve_type method" do
      union = Class.new(GraphQL::Schema::Union) do
        def self.resolve_type(_object, _context)
          "MyType"
        end

        def self.name
          "MyUnion"
        end
      end
      union_type = union.to_graphql
      assert_equal "MyType", union_type.resolve_type_proc.call(nil, nil)
    end

    it "passes on the possible type filter" do
      union_type = union.to_graphql
      expected_type = GraphQL::BaseType.resolve_related_type(Jazz::Musician)

      assert_equal [expected_type], union_type.possible_types(hide_ensemble: true)
    end
  end

  describe "in queries" do
    it "works" do
      query_str = <<-GRAPHQL
      {
        nowPlaying {
          ... on Musician {
            name
            instrument {
              family
            }
          }
          ... on Ensemble {
            name
          }
        }
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str)
      expected_data = { "name" => "Bela Fleck and the Flecktones" }
      assert_equal expected_data, res["data"]["nowPlaying"]
    end

    it "does not allow querying filtered types" do
      query_str = <<-GRAPHQL
      {
        nowPlaying {
          ... on Musician {
            name
            instrument {
              family
            }
          }
          ... on Ensemble {
            name
          }
        }
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str, context: { hide_ensemble: true })
      assert_equal 1, res.to_h["errors"].count
      assert_equal "Fragment on Ensemble can't be spread inside PerformingAct", res.to_h["errors"].first["message"]
    end

    it "can cast the object after resolving the type" do
      Box = Struct.new(:value)

      class Schema < GraphQL::Schema
        class A < GraphQL::Schema::Object
          field :a, String, null: false, method: :itself
        end

        class MyUnion < GraphQL::Schema::Union
          possible_types A

          def self.resolve_type(object, ctx)
            [A, object.value]
          end
        end

        class Query < GraphQL::Schema::Object
          field :my_union, MyUnion, null: false

          def my_union
            Box.new(context[:value])
          end
        end

        use GraphQL::Execution::Interpreter
        use GraphQL::Analysis::AST
        query(Query)
      end

      query_str = <<-GRAPHQL
      {
        myUnion {
          ... on A { a }
        }
      }
      GRAPHQL

      res = Schema.execute(query_str, context: { value: "unwrapped" })

      assert_equal({
        'data' => { 'myUnion' => { 'a' => 'unwrapped' } }
      }, res.to_h)
    end
  end

  it "doesn't allow adding interface" do
    object_type = Class.new(GraphQL::Schema::Object) do
      graphql_name "SomeObject"
    end

    interface_type = Module.new {
      include GraphQL::Schema::Interface
      graphql_name "SomeInterface"
    }

    err = assert_raises ArgumentError do
      Class.new(GraphQL::Schema::Union) do
        graphql_name "SomeUnion"
        possible_types object_type, interface_type
      end
    end

    expected_message = /Union possible_types can only be object types \(not interface types\), remove SomeInterface \(#<Module:0x[a-f0-9]+>\)/

    assert_match expected_message, err.message

    union_type = Class.new(GraphQL::Schema::Union) do
      graphql_name "SomeUnion"
      possible_types object_type, GraphQL::Schema::LateBoundType.new("SomeInterface")
    end

    err2 = assert_raises ArgumentError do
      Class.new(GraphQL::Schema) do
        query(object_type)
        orphan_types(union_type, interface_type)
      end
    end

    assert_match expected_message, err2.message
  end
end
