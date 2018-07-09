# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Union do
  let(:union) { Jazz::PerformingAct }
  describe "type info" do
    it "has some" do
      assert_equal 2, union.possible_types.size
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
  end
end
