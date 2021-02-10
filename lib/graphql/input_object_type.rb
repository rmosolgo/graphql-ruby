# frozen_string_literal: true
module GraphQL
  # @api deprecated
  class InputObjectType < GraphQL::BaseType
    extend Define::InstanceDefinable::DeprecatedDefine

    accepts_definitions(
      :arguments, :mutation,
      input_field: GraphQL::Define::AssignArgument,
      argument: GraphQL::Define::AssignArgument
    )

    attr_accessor :mutation, :arguments, :arguments_class
    ensure_defined(:mutation, :arguments, :input_fields)
    alias :input_fields :arguments

    # @!attribute mutation
    #   @return [GraphQL::Relay::Mutation, nil] The mutation this field was derived from, if it was derived from a mutation

    # @!attribute arguments
    # @return [Hash<String => GraphQL::Argument>] Map String argument names to their {GraphQL::Argument} implementations


    def initialize
      super
      @arguments = {}
    end

    def initialize_copy(other)
      super
      @arguments = other.arguments.dup
    end

    def kind
      GraphQL::TypeKinds::INPUT_OBJECT
    end

    def coerce_result(value, ctx = nil)
      if ctx.nil?
        warn_deprecated_coerce("coerce_isolated_result")
        ctx = GraphQL::Query::NullContext
      end

      # Allow the application to provide values as :symbols, and convert them to the strings
      value = value.reduce({}) { |memo, (k, v)| memo[k.to_s] = v; memo }

      result = {}

      arguments.each do |input_key, input_field_defn|
        input_value = value[input_key]
        if value.key?(input_key)
          result[input_key] = if input_value.nil?
            nil
          else
            input_field_defn.type.coerce_result(input_value, ctx)
          end
        end
      end

      result
    end

    def get_argument(argument_name)
      arguments[argument_name]
    end

    private

    def coerce_non_null_input(value, ctx)
      input_values = {}
      defaults_used = Set.new

      arguments.each do |input_key, input_field_defn|
        field_value = value[input_key]

        if value.key?(input_key)
          coerced_value = input_field_defn.type.coerce_input(field_value, ctx)
          input_values[input_key] = input_field_defn.prepare(coerced_value, ctx)
        elsif input_field_defn.default_value?
          coerced_value = input_field_defn.type.coerce_input(input_field_defn.default_value, ctx)
          input_values[input_key] = coerced_value
          defaults_used << input_key
        end
      end

      result = arguments_class.new(input_values, context: ctx, defaults_used: defaults_used)
      result.prepare
    end

    # @api private
    INVALID_OBJECT_MESSAGE = "Expected %{object} to be a key, value object responding to `to_h` or `to_unsafe_h`."

    def validate_non_null_input(input, ctx)
      warden = ctx.warden
      result = GraphQL::Query::InputValidationResult.new

      if input.is_a?(Array)
        result.add_problem(INVALID_OBJECT_MESSAGE % { object: JSON.generate(input, quirks_mode: true) })
        return result
      end

      # We're not actually _using_ the coerced result, we're just
      # using these methods to make sure that the object will
      # behave like a hash below, when we call `each` on it.
      begin
        input.to_h
      rescue
        begin
          # Handle ActionController::Parameters:
          input.to_unsafe_h
        rescue
          # We're not sure it'll act like a hash, so reject it:
          result.add_problem(INVALID_OBJECT_MESSAGE % { object: JSON.generate(input, quirks_mode: true) })
          return result
        end
      end

      visible_arguments_map = warden.arguments(self).reduce({}) { |m, f| m[f.name] = f; m}

      # Items in the input that are unexpected
      input.each do |name, value|
        if visible_arguments_map[name].nil?
          result.add_problem("Field is not defined on #{self.graphql_name}", [name])
        end
      end

      # Items in the input that are expected, but have invalid values
      visible_arguments_map.map do |name, field|
        field_result = field.type.validate_input(input[name], ctx)
        if !field_result.valid?
          result.merge_result!(name, field_result)
        end
      end

      result
    end
  end
end
