# frozen_string_literal: true
module GraphQL
  module Execution
    # This is one key-value pair in a GraphQL response.
    # @api private
    class FieldResult
      # @return [Any, Lazy] the GraphQL-ready response value, or a {Lazy} instance
      attr_reader :value

      # @return [SelectionResult] The result object that this field belongs to
      attr_reader :owner

      def initialize(type:, value:, owner:)
        @type = type
        @owner = owner
        self.value = value
      end

      # Set a new value for this field in the response.
      # It may be updated after resolving a {Lazy}.
      # If it is {Execute::PROPAGATE_NULL}, tell the owner to propagate null.
      # If the value is a {SelectionResult}, make a link with it, and if it's already null,
      # propagate the null as needed.
      # @param new_value [Any] The GraphQL-ready value
      def value=(new_value)
        if new_value.is_a?(SelectionResult)
          if new_value.invalid_null?
            new_value = GraphQL::Execution::Execute::PROPAGATE_NULL
          else
            new_value.owner = self
          end
        end

        if new_value == GraphQL::Execution::Execute::PROPAGATE_NULL
          if @type.kind.non_null?
            @owner.propagate_null
          else
            @value = nil
          end
        else
          @value = new_value
        end
      end

      def inspect
        "#<FieldResult #{value.inspect} (#{field.type})>"
      end
    end
  end
end
