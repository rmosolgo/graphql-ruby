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

  describe "when a member of a list of non-null type returns nil" do
    let(:schema) {
      node_type = GraphQL::ObjectType.define do
        name "Node"

        field :id, types.ID, "" do
          resolve ->(obj, args, ctx) {
            obj[:id]
          }
        end
      end

      query_type = GraphQL::ObjectType.define do
        name "Query"

        field :nonNullListWithNullStrings, types[!types.String], "" do
          resolve ->(obj, args, ctx) {
            [nil]
          }
        end

        field :nonNullListWithNullStringsLazy, types[!types.String], "" do
          resolve ->(obj, args, ctx) {
            LazyHelpers::Wrapper.new([nil])
          }
        end

        field :nonNullListWithNullTypes, types[!node_type], "" do
          resolve ->(obj, args, ctx) {
            [{ id: 1 }, nil, { id: 2 }]
          }
        end

        field :listWithNullStrings, types[types.String], "" do
          resolve ->(obj, args, ctx) {
            [nil, "hello"]
          }
        end

        field :listWithNullTypes, types[node_type], "" do
          resolve ->(obj, args, ctx) {
            [nil, { id: 1 }, nil]
          }
        end

        field :nonNullList, !types[!types.String], "" do
          resolve ->(obj, args, ctx) {
            [nil]
          }
        end
      end

      GraphQL::Schema.define do
        query query_type
        lazy_resolve(LazyHelpers::Wrapper, :item)
      end
    }

    it "propagates null for non-lazy resolvers" do
      query = <<-GRAPHQL
      {
        nonNullListWithNullStrings
        nonNullListWithNullTypes {
          id
        }
        listWithNullStrings
        listWithNullTypes {
          id
        }
      }
      GRAPHQL

      result = schema.execute(query).to_h

      assert_equal ["nonNullListWithNullStrings", "nonNullListWithNullTypes", "listWithNullStrings", "listWithNullTypes"], result["data"].keys

      assert_equal nil, result["data"]["nonNullListWithNullStrings"]
      assert_equal nil, result["data"]["nonNullListWithNullTypes"]
      assert_equal [nil, "hello"], result["data"]["listWithNullStrings"]
      assert_equal [nil, { "id" => "1" }, nil], result["data"]["listWithNullTypes"]
    end

    it "propagates null for lazy resolvers" do
      result = schema.execute("{ nonNullListWithNullStringsLazy }").to_h

      assert_equal ["nonNullListWithNullStringsLazy"], result["data"].keys

      assert_equal nil, result["data"]["nonNullListWithNullStringsLazy"]
    end

    it "propagates null for non-null lists of non-null types" do
      result = schema.execute("{ nonNullList }").to_h

      assert_equal nil, result["data"]
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

      assert_nil res["data"]
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

  describe "tracing" do
    if rails_should_be_installed?
      it "emits traces" do
        query_string = <<-GRAPHQL
        query Bases($id1: ID!, $id2: ID!){
          b1: batchedBase(id: $id1) { name }
          b2: batchedBase(id: $id2) { name }
        }
        GRAPHQL
        first_id = StarWars::Base.first.id
        last_id = StarWars::Base.last.id

        traces = TestTracing.with_trace do
          star_wars_query(query_string, {
            "id1" => first_id,
            "id2" => last_id,
          }, context: {tracers: [TestTracing]})
        end

        exec_traces = traces[5..-1]
        expected_traces = [
          "execute_field",
          "execute_field",
          "execute_query",
          "lazy_loader",
          "execute_field_lazy",
          "execute_field",
          "execute_field_lazy",
          "execute_field",
          "execute_field_lazy",
          "execute_field_lazy",
          "execute_query_lazy",
          "execute_multiplex",
        ]
        assert_equal expected_traces, exec_traces.map { |t| t[:key] }

        field_1_eager, field_2_eager,
          query_eager, lazy_loader,
          # field 3 is eager-resolved _during_ field 1's lazy resolve
          field_1_lazy, field_3_eager,
          field_2_lazy, field_4_eager,
          # field 3 didn't finish above, it's resolved in the next round
          field_3_lazy, field_4_lazy,
          query_lazy, multiplex = exec_traces

        assert_equal ["b1"], field_1_eager[:context].path
        assert_equal ["b2"], field_2_eager[:context].path
        assert_instance_of GraphQL::Query, query_eager[:query]

        assert_equal [first_id.to_s, last_id.to_s], lazy_loader[:ids]
        assert_equal StarWars::Base, lazy_loader[:model]

        assert_equal ["b1", "name"], field_3_eager[:context].path
        assert_equal ["b1"], field_1_lazy[:context].path
        assert_equal ["b2", "name"], field_4_eager[:context].path
        assert_equal ["b2"], field_2_lazy[:context].path

        assert_equal ["b1", "name"], field_3_lazy[:context].path
        assert_equal ["b2", "name"], field_4_lazy[:context].path
        assert_instance_of GraphQL::Query, query_lazy[:query]

        assert_instance_of GraphQL::Execution::Multiplex, multiplex[:multiplex]
      end
    end
  end
end
