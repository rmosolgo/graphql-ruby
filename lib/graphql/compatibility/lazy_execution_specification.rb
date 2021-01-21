# frozen_string_literal: true
require "graphql/compatibility/lazy_execution_specification/lazy_schema"

module GraphQL
  module Compatibility
    module LazyExecutionSpecification
      # @param execution_strategy [<#new, #execute>] An execution strategy class
      # @return [Class<Minitest::Test>] A test suite for this execution strategy
      def self.build_suite(execution_strategy)
        GraphQL::Deprecation.warn "#{self} will be removed from GraphQL-Ruby 2.0. There is no replacement, please open an issue on GitHub if you need support."

        Class.new(Minitest::Test) do
          class << self
            attr_accessor :lazy_schema
          end

          self.lazy_schema = LazySchema.build(execution_strategy)

          def test_it_resolves_lazy_values
            pushes = []
            query_str = %|
            {
              p1: push(value: 1) {
                value
              }
              p2: push(value: 2) {
                push(value: 3) {
                  value
                  push(value: 21) {
                    value
                  }
                }
              }
              p3: push(value: 4) {
                push(value: 5) {
                  value
                  push(value: 22) {
                    value
                  }
                }
              }
            }
            |
            res = self.class.lazy_schema.execute(query_str, context: {pushes: pushes})

            expected_data = {
              "p1"=>{"value"=>1},
              "p2"=>{"push"=>{"value"=>3, "push"=>{"value"=>21}}},
              "p3"=>{"push"=>{"value"=>5, "push"=>{"value"=>22}}},
            }
            assert_equal expected_data, res["data"]

            expected_pushes = [
              [1,2,4], # first level
              [3,5], # second level
              [21, 22],
            ]
            assert_equal expected_pushes, pushes
          end

          def test_it_maintains_path
            query_str = %|
            {
              push(value: 2) {
                push(value: 3) {
                  fail1: push(value: 14) {
                    value
                  }
                  fail2: push(value: 14) {
                    value
                  }
                }
              }
            }
            |
            res = self.class.lazy_schema.execute(query_str, context: {pushes: []})
            assert_equal nil, res["data"]
            # The first fail causes the second field to never resolve
            assert_equal 1, res["errors"].length
            assert_equal ["push", "push", "fail1", "value"], res["errors"][0]["path"]
          end

          def test_it_resolves_mutation_values_eagerly
            pushes = []
            query_str = %|
            mutation {
              p1: push(value: 1) {
                value
              }
              p2: push(value: 2) {
                push(value: 3) {
                  value
                }
              }
              p3: push(value: 4) {
                p5: push(value: 5) {
                  value
                }
                p6: push(value: 6) {
                  value
                }
              }
            }
            |
            res = self.class.lazy_schema.execute(query_str, context: {pushes: pushes})

            expected_data = {
              "p1"=>{"value"=>1},
              "p2"=>{"push"=>{"value"=>3}},
              "p3"=>{"p5"=>{"value"=>5},"p6"=>{"value"=>6}},
            }
            assert_equal expected_data, res["data"]

            expected_pushes = [
              [1],        # first operation
              [2], [3],   # second operation
              [4], [5, 6], # third operation
            ]
            assert_equal expected_pushes, pushes
          end

          def test_it_resolves_lazy_connections
            pushes = []
            query_str = %|
            {
              pushes(values: [1,2,3]) {
                edges {
                  node {
                    value
                    push(value: 4) {
                      value
                    }
                  }
                }
              }
            }
            |
            res = self.class.lazy_schema.execute(query_str, context: {pushes: pushes})

            expected_edges = [
              {"node"=>{"value"=>1, "push"=>{"value"=>4}}},
              {"node"=>{"value"=>2, "push"=>{"value"=>4}}},
              {"node"=>{"value"=>3, "push"=>{"value"=>4}}},
            ]
            assert_equal expected_edges, res["data"]["pushes"]["edges"]
            assert_equal [[1, 2, 3], [4, 4, 4]], pushes
          end

          def test_it_calls_lazy_resolve_instrumentation
            query_str = %|
            {
              p1: push(value: 1) {
                value
              }
              p2: push(value: 2) {
                push(value: 3) {
                  value
                }
              }
              pushes(values: [1,2,3]) {
                edges {
                  node {
                    value
                    push(value: 4) {
                      value
                    }
                  }
                }
              }
            }
            |

            log = []
            self.class.lazy_schema.execute(query_str, context: {lazy_instrumentation: log, pushes: []})
            expected_log = [
              "PUSH",
              "Query.push: 1",
              "Query.push: 2",
              "Query.pushes: [1, 2, 3]",
              "PUSH",
              "LazyPush.push: 3",
              "LazyPushEdge.node: 1",
              "LazyPushEdge.node: 2",
              "LazyPushEdge.node: 3",
              "PUSH",
              "LazyPush.push: 4",
              "LazyPush.push: 4",
              "LazyPush.push: 4",
            ]
            assert_equal expected_log, log
          end

          def test_it_skips_ctx_skip
            query_string = <<-GRAPHQL
            {
              p0: push(value: 15) { value }
              p1: push(value: 1) { value }
              p2: push(value: 2) {
                value
                p3: push(value: 15) {
                  value
                }
              }
            }
            GRAPHQL
            pushes = []
            res = self.class.lazy_schema.execute(query_string, context: {pushes: pushes})
            assert_equal [[1,2]], pushes
            assert_equal({"data"=>{"p1"=>{"value"=>1}, "p2"=>{"value"=>2}}}, res)
          end
        end
      end
    end
  end
end
