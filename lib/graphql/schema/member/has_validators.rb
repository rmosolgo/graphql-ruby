# frozen_string_literal: true
module GraphQL
  class Schema
    class Member
      module HasValidators
        include Schema::FindInheritedValue::EmptyObjects

        # Build {GraphQL::Schema::Validator}s based on the given configuration
        # and use them for this schema member
        # @param validation_config [Hash{Symbol => Hash}]
        # @return [void]
        def validates(validation_config)
          new_validators = GraphQL::Schema::Validator.from_config(self, validation_config)
          @own_validators ||= []
          @own_validators.concat(new_validators)
          nil
        end

        # @return [Array<GraphQL::Schema::Validator>]
        def validators
          own_validators = @own_validators || EMPTY_ARRAY
          if self.is_a?(Class) && superclass.respond_to?(:validators) && (inherited_validators = superclass.validators).any?
            inherited_validators + own_validators
          else
            own_validators
          end
        end
      end
    end
  end
end
