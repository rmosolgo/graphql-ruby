module GraphQL
  module Execution
    class FieldResult
      attr_reader :value, :parent_type, :field, :name, :owner
      def initialize(parent_type:, field:, value:, name:, owner:)
        @parent_type = parent_type
        @field = field
        @owner = owner
        @name = name
        self.value = value
      end

      def value=(new_value)
        if new_value.is_a?(SelectionResult)
          if new_value.invalid_null?
            new_value = new_value.invalid_null
          else
            new_value.owner = self
          end
        end

        if new_value == GraphQL::Execution::Execute::PROPAGATE_NULL
          if field.type.kind.non_null?
            @owner.propagate_null(@name, new_value)
          else
            @value = nil
          end
        else
          @value = new_value
        end
      end

      def inspect
        "#<FieldResult #{name.inspect} => #{value.inspect} (#{field.type})>"
      end
    end
  end
end
