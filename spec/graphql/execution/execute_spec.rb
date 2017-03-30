# frozen_string_literal: true
require "spec_helper"

ExecuteSuite = GraphQL::Compatibility::ExecutionSpecification.build_suite(GraphQL::Execution::Execute)
LazyExecuteSuite = GraphQL::Compatibility::LazyExecutionSpecification.build_suite(GraphQL::Execution::Execute)

describe GraphQL::Execution::Execute do
  describe "null propagation on mutation root" do
    module MutationNullTestRoot
      INTS = []
      def self.push(args, ctx)
        if args[:int] == 13
          nil
        else
          INTS << args[:int]
          args[:int]
        end
      end

      def ints
        INTS
      end
    end

    let(:root) { MutationNullTestRoot }

    let(:query_str) do
      <<-GRAPHQL
      mutation {
        one: push(int: 1)
        thirteen: push(int: 13)
        two: push(int: 2)
      }
      GRAPHQL
    end

    before do
      MutationNullTestRoot::INTS.clear
    end

    describe "when root fields are non-nullable" do
      let(:schema) { GraphQL::Schema.from_definition <<-GRAPHQL
        type Mutation {
          push(int: Int!): Int!
        }

        type Query {
          ints: [Int!]
        }
      GRAPHQL
      }

      it "propagates null to the root mutation and halts mutation execution" do
        res = schema.execute(query_str, root_value: root)
        assert_equal [1], MutationNullTestRoot::INTS
        assert_equal(nil, res["data"])
      end
    end

    describe 'mutation fields are nullable' do
      let(:schema) { GraphQL::Schema.from_definition <<-GRAPHQL
        type Mutation {
          push(int: Int!): Int
        }

        type Query {
          ints: [Int!]
        }
      GRAPHQL
      }

      it 'does not halt execution and returns data for the successful mutations' do
        res = schema.execute(query_str, root_value: root)
        assert_equal [1, 2], MutationNullTestRoot::INTS
        assert_equal({"one"=>1, "thirteen"=>nil, "two"=>2}, res["data"])
      end
    end
  end

  describe "when a list member raises an error" do
    let(:schema) {
      thing_type = GraphQL::ObjectType.define do
        name "Thing"
        field :name, !types.String do
          resolve ->(o, a, c) {
            -> {
              raise GraphQL::ExecutionError.new("👻")
            }
          }
        end
      end

      query_type = GraphQL::ObjectType.define do
        name "Query"
        field :things, !types[!thing_type] do
          resolve ->(o, a, c) {
            [OpenStruct.new(name: "A")]
          }
        end

        field :nullableThings, !types[thing_type] do
          resolve ->(o, a, c) {
            [OpenStruct.new(name: "A")]
          }
        end
      end

      GraphQL::Schema.define do
        query query_type
        lazy_resolve(Proc, :call)
      end
    }

    it "handles the error & propagates the null" do
      res = schema.execute <<-GRAPHQL
      {
        things {
          name
        }
      }
      GRAPHQL

      assert_equal nil, res["data"]
      assert_equal "👻", res["errors"].first["message"]
    end

    it "allows nulls" do
      res = schema.execute <<-GRAPHQL
      {
        nullableThings {
          name
        }
      }
      GRAPHQL

      assert_equal [nil], res["data"]["nullableThings"]
      assert_equal "👻", res["errors"].first["message"]
    end
  end
end
