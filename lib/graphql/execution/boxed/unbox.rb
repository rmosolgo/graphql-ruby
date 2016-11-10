module GraphQL
  module Execution
    class Boxed
      # Helpers for dealing with data structures containing {Boxed} instances
      module Unbox
        # Mutate `value`, replacing {Boxed} instances in place with their resolved values
        # @return [void]
        def self.unbox_in_place(value)
          boxes = []

          each_box(value) do |field_result|
            inner_b = field_result.value.then do |inner_v|
              field_result.value = inner_v
              unbox_in_place(inner_v)
            end
            boxes.push(inner_b)
          end

          Boxed.new { boxes.map(&:value) }
        end

        # If `value` is a collection, call `block`
        # with any {Boxed} instances in the collection
        # @return [void]
        def self.each_box(value, &block)
          case value
          when SelectionResult
            value.each do |key, field_result|
              each_box(field_result, &block)
            end
          when Array
            value.each do |field_result|
              each_box(field_result, &block)
            end
          when FieldResult
            field_value = value.value
            if field_value.is_a?(Boxed)
              yield(value)
            else
              each_box(field_value, &block)
            end
          end
        end

        # Traverse `val`, triggering resolution for each {Boxed}.
        # These {Boxed}s are expected to mutate their owner data structures
        # during resolution! (They're created with the `.then` calls in `unbox_in_place`).
        # @return [void]
        def self.deep_sync(val)
          case val
          when Boxed
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
