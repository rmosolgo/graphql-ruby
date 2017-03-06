# frozen_string_literal: true
require "spec_helper"

ExecuteSuite = GraphQL::Compatibility::ExecutionSpecification.build_suite(GraphQL::Execution::Execute)
LazyExecuteSuite = GraphQL::Compatibility::LazyExecutionSpecification.build_suite(GraphQL::Execution::Execute)

describe GraphQL::Execution::Execute do
  describe "null values on mutation roots" do
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

    let(:schema) { GraphQL::Schema.from_definition <<-GRAPHQL
      type Mutation {
        push(int: Int!): Int!
      }

      type Query {
        ints: [Int!]
      }
    GRAPHQL
    }

    let(:root) { MutationNullTestRoot }

    before do
      MutationNullTestRoot::INTS.clear
    end

    it "returns values for other mutations" do
      query_str = <<-GRAPHQL
      mutation {
        one: push(int: 1)
        thirteen: push(int: 13)
        two: push(int: 2)
      }
      GRAPHQL

      res = schema.execute(query_str, root_value: root)
      assert_equal [1], MutationNullTestRoot::INTS
      assert_equal(nil, res["data"])
    end
  end
end
