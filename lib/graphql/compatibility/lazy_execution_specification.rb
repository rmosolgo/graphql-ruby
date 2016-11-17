require "graphql/compatibility/lazy_execution_specification/lazy_schema"

module GraphQL
  module Compatibility
    module LazyExecutionSpecification
      # @param execution_strategy [<#new, #execute>] An execution strategy class
      # @return [Class<Minitest::Test>] A test suite for this execution strategy
      def self.build_suite(execution_strategy)
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
                }
              }
              p3: push(value: 4) {
                push(value: 5) {
                  value
                }
              }
            }
            |
            res = self.class.lazy_schema.execute(query_str, context: {pushes: pushes})

            expected_data = {
              "p1"=>{"value"=>1},
              "p2"=>{"push"=>{"value"=>3}},
              "p3"=>{"push"=>{"value"=>5}},
            }
            assert_equal expected_data, res["data"]

            expected_pushes = [
              [1,2,4], # first level
              [3,5], # second level
            ]
            assert_equal expected_pushes, pushes
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
              [4], [5,6], # third operation
            ]
            assert_equal expected_pushes, pushes
          end
        end
      end
    end
  end
end
