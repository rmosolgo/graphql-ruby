# frozen_string_literal: true
module GraphQL
  module Compatibility
    module LazyExecutionSpecification
      module LazySchema
        class LazyPush
          attr_reader :value
          def initialize(ctx, value)
            if value == 13
              @value = nil
            elsif value == 14
              @value = GraphQL::ExecutionError.new("oops!")
            elsif value == 15
              @skipped = true
              @value = ctx.skip
            else
              @value = value
            end
            @context = ctx
            pushes = @context[:lazy_pushes] ||= []
            if !@skipped
              pushes << @value
            end
          end

          def push
            if @skipped
              @value
            else
              if @context[:lazy_pushes].include?(@value)
                @context[:lazy_instrumentation] && @context[:lazy_instrumentation] << "PUSH"
                @context[:pushes] << @context[:lazy_pushes]
                @context[:lazy_pushes] = []
              end
              # Something that _behaves_ like this object, but isn't registered lazy
              OpenStruct.new(value: @value)
            end
          end
        end

        class LazyPushCollection
          def initialize(ctx, values)
            @ctx = ctx
            @values = values
          end

          def push
            @values.map { |v| LazyPush.new(@ctx, v) }
          end

          def value
            @values
          end
        end

        module LazyInstrumentation
          def self.instrument(type, field)
            prev_lazy_resolve = field.lazy_resolve_proc
            field.redefine {
              lazy_resolve ->(o, a, c) {
                result = prev_lazy_resolve.call(o, a, c)
                c[:lazy_instrumentation] && c[:lazy_instrumentation].push("#{type.name}.#{field.name}: #{o.value}")
                result
              }
            }
          end
        end

        def self.build(execution_strategy)
          lazy_push_type = GraphQL::ObjectType.define do
            name "LazyPush"
            field :value, !types.Int
            field :push, !lazy_push_type do
              argument :value, types.Int
              resolve ->(o, a, c) {
                LazyPush.new(c, a[:value])
              }
            end
          end

          query_type = GraphQL::ObjectType.define do
            name "Query"
            field :push, !lazy_push_type do
              argument :value, types.Int
              resolve ->(o, a, c) {
                LazyPush.new(c, a[:value])
              }
            end

            connection :pushes, lazy_push_type.connection_type do
              argument :values, types[types.Int], method_access: false
              resolve ->(o, a, c) {
                LazyPushCollection.new(c, a[:values])
              }
            end
          end

          GraphQL::Schema.define do
            query(query_type)
            mutation(query_type)
            query_execution_strategy(execution_strategy)
            mutation_execution_strategy(execution_strategy)
            lazy_resolve(LazyPush, :push)
            lazy_resolve(LazyPushCollection, :push)
            instrument(:field, LazyInstrumentation)
          end
        end
      end
    end
  end
end
