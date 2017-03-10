# frozen_string_literal: true
module GraphQL
  module Execution
    # A set of key-value pairs suitable for a GraphQL response.
    # @api private
    class SelectionResult
      def initialize
        @storage = {}
        @owner = nil
        @invalid_null = false
      end

      # @param key [String] The name for this value in the result
      # @param field_result [FieldResult] The result for this field
      def set(key, field_result)
        @storage[key] = field_result
      end

      # @param key [String] The name of an already-defined result
      # @return [FieldResult] The result for this field
      def fetch(key)
        @storage.fetch(key)
      end

      # Visit each key-result pair in this result
      def each
        @storage.each do |key, field_res|
          yield(key, field_res)
        end
      end

      # @return [Hash] A plain Hash representation of this result
      def to_h
        if @invalid_null
          nil
        else
          flatten(self)
        end
      end

      # A field has been unexpectedly nullified.
      # Tell the owner {FieldResult} if it is present.
      # Record {#invalid_null} in case an owner is added later.
      def propagate_null
        if @owner
          @owner.value = GraphQL::Execution::Execute::PROPAGATE_NULL
        end
        @invalid_null = true
      end

      # @return [Boolean] True if this selection has been nullified by a null child
      def invalid_null?
        @invalid_null
      end

      # @param field_result [FieldResult] The field that this selection belongs to (used for propagating nulls)
      def owner=(field_result)
        if @owner
          raise("Can't change owners of SelectionResult")
        else
          @owner = field_result
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
