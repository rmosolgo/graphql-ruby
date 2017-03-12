# frozen_string_literal: true
module GraphQL
  module Execution
    class Lazy
      # Helpers for dealing with data structures containing {Lazy} instances
      # @api private
      module Resolve
        # Mutate `value`, replacing {Lazy} instances in place with their resolved values
        # @return [void]
        def self.resolve(value)
          lazies = resolve_in_place(value)
          deep_sync(lazies)
        end

        def self.resolve_in_place(value)
          lazies = []

          each_lazy(value) do |field_result|
            inner_lazy = field_result.value.then do |inner_v|
              field_result.value = inner_v
              resolve_in_place(inner_v)
            end
            lazies.push(inner_lazy)
          end

          Lazy.new { lazies.map(&:value) }
        end

        # If `value` is a collection, call `block`
        # with any {Lazy} instances in the collection
        # @return [void]
        def self.each_lazy(value, &block)
          case value
          when SelectionResult
            value.each do |key, field_result|
              each_lazy(field_result, &block)
            end
          when Array
            value.each do |field_result|
              each_lazy(field_result, &block)
            end
          when FieldResult
            field_value = value.value
            if field_value.is_a?(Lazy)
              yield(value)
            else
              each_lazy(field_value, &block)
            end
          end
        end

        # Traverse `val`, triggering resolution for each {Lazy}.
        # These {Lazy}s are expected to mutate their owner data structures
        # during resolution! (They're created with the `.then` calls in `resolve_in_place`).
        # @return [void]
        def self.deep_sync(val)
          case val
          when Lazy
            deep_sync(val.value)
          when Array
            val.each { |v| deep_sync(v.value) }
          when Hash
            val.each { |k, v| deep_sync(v.value) }
          end
        end
      end
    end
  end
end
