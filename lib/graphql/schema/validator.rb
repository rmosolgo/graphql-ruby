# frozen_string_literal: true

module GraphQL
  class Schema
    class Validator
      # @return [GraphQL::Schema::Argument]
      attr_reader :argument
      # @return [Hash<Symbol => Object>]
      attr_reader :options

      # @param argument [GraphQL::Schema::Argument] The argument this validator is attached to
      # @param options [Hash] Any other validation-specific options provided to this validator
      def initialize(argument, **options)
        @argument = argument
        @options = options
      end

      # @param object [Object] The application object that this argument's field is being resolved for
      # @param context [GraphQL::Query::Context]
      # @param value [Object] The client-provided value for this argument (after parsing and coercing by the input type)
      # @return [nil, Array<String>, String] Error message or messages to add
      def validate(object, context, value)
        nil
      end

      # @param validates_hash [Hash, nil] A configuration passed as `validates:`
      # @return [Array<Validator>]
      def self.from_config(schema_member, validates_hash)
        if validates_hash.nil? || validates_hash.empty?
          EMPTY_ARRAY
        else
          validates_hash.map do |validator_name, options|
            validator_class = all_validators[validator_name] || raise(ArgumentError, "unknown validation: #{validator_name.inspect}")
            validator_class.new(schema_member, **options)
          end
        end
      end

      def self.install(name, validator)
        all_validators[name] = validator
      end

      class << self
        attr_accessor :all_validators
      end

      self.all_validators = {}

      include Schema::FindInheritedValue::EmptyObjects

      class ValidationFailedError < GraphQL::ExecutionError
        attr_reader :errors

        def initialize(errors:)
          @errors = errors
          super(errors.join(", "))
        end
      end

      # @param validators [Array<Validator>]
      # @param object [Object]
      # @param context [Query::Context]
      # @param value [Object]
      # @return [void]
      # @raises [ValidationFailedError]
      def self.validate!(validators, object, context, value)
        # Assuming the default case is no errors, reduce allocations in that case.
        # This will be replaced with a mutable array if we actually get any errors.
        all_errors = EMPTY_ARRAY

        validators.each do |validator|
          errors = validator.validate(object, context, value)
          if errors &&
            (errors.is_a?(Array) && errors != EMPTY_ARRAY) ||
            (errors.is_a?(String))
            if all_errors.frozen? # It's empty
              all_errors = []
            end
            if errors.is_a?(String)
              all_errors << errors
            else
              all_errors.concat(errors)
            end
          end
        end

        if all_errors.any?
          raise ValidationFailedError.new(errors: all_errors)
        end
        nil
      end
    end
  end
end


require "graphql/schema/validator/length_validator"

GraphQL::Schema::Validator.install(:length, GraphQL::Schema::Validator::LengthValidator)
