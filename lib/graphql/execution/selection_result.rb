module GraphQL
  module Execution
    class SelectionResult
      def initialize(type:)
        @type = type
        @storage = {}
        @owner = nil
        @invalid_null = false
      end

      def set(key, field_result)
        @storage[key] = field_result
      end

      def fetch(key)
        @storage.fetch(key)
      end

      def each
        @storage.each do |key, field_res|
          yield(key, field_res)
        end
      end

      def to_h
        if @invalid_null
          nil
        else
          flatten(self)
        end
      end

      def propagate_null(key, value)
        if @owner
          @owner.value = value
        end
        @invalid_null = value
      end

      def invalid_null?
        @invalid_null
      end

      def invalid_null
        @invalid_null
      end

      def owner=(field_result)
        if @owner
          raise("Can't change owners of SelectionResult")
        else
          @owner = field_result
          if @invalid_null
            @owner.value = @invalid_null
          end
        end
      end

      private

      def flatten(obj)
        case obj
        when SelectionResult
          flattened = {}
          obj.each do |key, val|
            flattened[key] = flatten(val)
          end
          flattened
        when Array
          obj.map { |v| flatten(v) }
        when FieldResult
          flatten(obj.value)
        else
          obj
        end
      end
    end
  end
end
