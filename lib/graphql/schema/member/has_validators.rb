# frozen_string_literal: true
module GraphQL
  class Schema
    class Member
      module HasValidators
        include GraphQL::EmptyObjects

        # Build {GraphQL::Schema::Validator}s based on the given configuration
        # and use them for this schema member
        # @param validation_config [Hash{Symbol => Hash}]
        # @return [void]
        def validates(validation_config)
          validation_config.each do |validator_name, _options|
            if validator_name.is_a?(Class) || !GraphQL::Schema::Validator.all_validators.key?(validator_name)
                warn <<~WARN
                  WARNING: GraphQL Custom validator '#{validator_name}' detected at #{caller(1,1).first}
                  Custom validators with I/O operations may fail unexpectedly due to GraphQL's default validate_timeout setting. Long-running I/O operations may not be killed halfway through, resulting in unpredictable behavior. See https://graphql-ruby.org/queries/timeout.html#validation-and-analysis for more information.
                WARN
            end
          end

          new_validators = GraphQL::Schema::Validator.from_config(self, validation_config)
          @own_validators ||= []
          @own_validators.concat(new_validators)
          nil
        end

        # @return [Array<GraphQL::Schema::Validator>]
        def validators
          @own_validators || EMPTY_ARRAY
        end

        module ClassConfigured
          def inherited(child_cls)
            super
            child_cls.extend(ClassValidators)
          end

          module ClassValidators
            include GraphQL::EmptyObjects

            def validators
              inherited_validators = superclass.validators
              if !inherited_validators.empty?
                if @own_validators.nil?
                  inherited_validators
                else
                  inherited_validators + @own_validators
                end
              elsif @own_validators.nil?
                EMPTY_ARRAY
              else
                @own_validators
              end
            end
          end
        end

        def self.extended(child_cls)
          super
          child_cls.extend(ClassConfigured)
        end
      end
    end
  end
end
