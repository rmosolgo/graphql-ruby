module GraphQL
  module Compatibility
    module LazyExecutionSpecification
      module LazySchema
        class LazyPush
          attr_reader :value
          def initialize(ctx, value)
            @value = value
            @context = ctx
            pushes = @context[:lazy_pushes] ||= []
            pushes << @value
          end

          def push
            if @context[:lazy_pushes].include?(@value)
              @context[:pushes] << @context[:lazy_pushes]
              @context[:lazy_pushes] = []
            end
            self
          end
        end

        def self.build(execution_strategy)
          lazy_push_type = GraphQL::ObjectType.define do
            name "LazyPush"
            field :value, types.Int
            field :push, lazy_push_type do
              argument :value, types.Int
              resolve ->(o, a, c) {
                LazyPush.new(c, a[:value])
              }
            end
          end

          query_type = GraphQL::ObjectType.define do
            name "Query"
            field :push, lazy_push_type do
              argument :value, types.Int
              resolve ->(o, a, c) {
                LazyPush.new(c, a[:value])
              }
            end
          end

          GraphQL::Schema.define do
            query(query_type)
            mutation(query_type)
            query_execution_strategy(execution_strategy)
            lazy_resolve(LazyPush, :push)
          end
        end
      end
    end
  end
end
