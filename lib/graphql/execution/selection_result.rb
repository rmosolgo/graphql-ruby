module GraphQL
  module Execution
    class SelectionResult
      def initialize
        @storage = {}
      end

      def set(key, value, type)
        @storage[key] = FieldResult.new(type: type, value: value)
      end

      def [](key)
        @storage.fetch(key).value
      end

      def []=(key, value)
        @storage.fetch(key).value = value
      end

      def each
        @storage.each do |key, field_res|
          yield(key, field_res.value, field_res)
        end
      end

      def to_h
        flatten(self)
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
        else
          obj
        end
      end

      class FieldResult
        attr_reader :type
        attr_accessor :value
        def initialize(type:, value:)
          @type = type
          @value = value
        end
      end
    end
  end
end
