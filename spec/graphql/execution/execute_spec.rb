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

  describe "execute wrapper" do
    let(:schema) {
      DummyQueryType = GraphQL::ObjectType.define do
        name "Query"
        field :dairy do
          type Dummy::DairyType
          resolve ->(t, a, c) {
            Dummy::DAIRY
          }
        end
      end

      GraphQL::Schema.define(query: DummyQueryType, mutation: Dummy::DairyAppMutationType, resolve_type: :pass, id_from_object: :pass)
    }

    let(:query_string) { %|
      query getDairy {
        dairy {
          id
        }
      }
    |}

    let(:mutation_string) {%|
      mutation setInOrder {
        first:  pushValue(value: 1)
        second: pushValue(value: 5)
        third:  pushValue(value: 2)
        fourth: replaceValues(input: {values: [6,5,4]})
      }
    |}

    let(:execute_wrapper) do
      Proc.new do |query|
        if query.mutation?
          raise RuntimeError
        else
          raise TypeError
        end
      end
    end

    it 'calls on queries when provided' do
      assert_raises(TypeError) { schema.execute(query_string, execute_wrapper: execute_wrapper) }
    end

    it 'calls on mutations when provided' do
      assert_raises(RuntimeError) { schema.execute(mutation_string, execute_wrapper: execute_wrapper) }
    end
  end
end
