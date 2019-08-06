# frozen_string_literal: true
module GraphQL
  module Compatibility
    module ExecutionSpecification
      module CounterSchema
        def self.build(execution_strategy)
          counter_type = nil
          schema = nil

          has_count_interface = GraphQL::InterfaceType.define do
            name "HasCount"
            field :count, types.Int
            field :counter, ->{ has_count_interface }
          end

          counter_type = GraphQL::ObjectType.define do
            name "Counter"
            interfaces [has_count_interface]
            field :count, types.Int, resolve: ->(o,a,c) { schema.metadata[:count] += 1 }
            field :counter, has_count_interface, resolve: ->(o,a,c) { :counter }
          end

          alt_counter_type = GraphQL::ObjectType.define do
            name "AltCounter"
            interfaces [has_count_interface]
            field :count, types.Int, resolve: ->(o,a,c) { schema.metadata[:count] += 1 }
            field :counter, has_count_interface, resolve: ->(o,a,c) { :counter }
          end

          has_counter_interface = GraphQL::InterfaceType.define do
            name "HasCounter"
            field :counter, has_count_interface
          end

          query_type = GraphQL::ObjectType.define do
            name "Query"
            interfaces [has_counter_interface]
            field :counter, has_count_interface, resolve: ->(o,a,c) { :counter }
          end

          schema = GraphQL::Schema.define(
            query: query_type,
            resolve_type: ->(t, o, c) { o == :counter ? counter_type : nil },
            orphan_types: [alt_counter_type, counter_type],
            query_execution_strategy: execution_strategy,
          )
          schema.metadata[:count] = 0
          schema
        end
      end
    end
  end
end
