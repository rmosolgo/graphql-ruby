# frozen_string_literal: true
module GraphQL
  # {InputObjectType}s are key-value inputs for fields.
  #
  # Input objects have _arguments_ which are identical to {GraphQL::Field} arguments.
  # They map names to types and support default values.
  # Their input types can be any input types, including {InputObjectType}s.
  #
  # @example An input type with name and number
  #   PlayerInput = GraphQL::InputObjectType.define do
  #     name("Player")
  #     argument :name, !types.String
  #     argument :number, !types.Int
  #   end
  #
  # In a `resolve` function, you can access the values by making nested lookups on `args`.
  #
  # @example Accessing input values in a resolve function
  #   resolve ->(obj, args, ctx) {
  #     args[:player][:name]    # => "Tony Gwynn"
  #     args[:player][:number]  # => 19
  #     args[:player].to_h      # { "name" => "Tony Gwynn", "number" => 19 }
  #     # ...
  #   }
  #
  class InputObjectType < GraphQL::BaseType
    accepts_definitions(
      :arguments, :mutation,
      input_field: GraphQL::Define::AssignArgument,
      argument: GraphQL::Define::AssignArgument
    )

    attr_accessor :mutation, :arguments
    ensure_defined(:mutation, :arguments)
    alias :input_fields :arguments

    # @!attribute mutation
    #   @return [GraphQL::Relay::Mutation, nil] The mutation this field was derived from, if it was derived from a mutation

    # @!attribute arguments
    # @return [Hash<String => GraphQL::Argument>] Map String argument names to their {GraphQL::Argument} implementations


    def initialize
      @arguments = {}
    end

    def initialize_copy(other)
      super
      @arguments = other.arguments.dup
    end

    def kind
      GraphQL::TypeKinds::INPUT_OBJECT
    end

    def validate_non_null_input(input, warden)
      result = GraphQL::Query::InputValidationResult.new

      if (input.to_h rescue nil).nil?
        result.add_problem(
          "Expected #{JSON.generate(input, quirks_mode: true)} to be a key, value object " \
          " responding to `to_h`."
        )
        return result
      end


      visible_arguments_map = warden.arguments(self).reduce({}) { |m, f| m[f.name] = f; m}

      # Items in the input that are unexpected
      input.each do |name, value|
        if visible_arguments_map[name].nil?
          result.add_problem("Field is not defined on #{self.name}", [name])
        end
      end

      # Items in the input that are expected, but have invalid values
      visible_arguments_map.map do |name, field|
        field_result = field.type.validate_input(input[name], warden)
        if !field_result.valid?
          result.merge_result!(name, field_result)
        end
      end

      result
    end

    def coerce_non_null_input(value)
      input_values = {}

      arguments.each do |input_key, input_field_defn|
        field_value = value[input_key]

        if value.key?(input_key)
          coerced_value = input_field_defn.type.coerce_input(field_value)
        else
          coerced_value = input_field_defn.default_value
        end

        input_values[input_key] = coerced_value if coerced_value || value.key?(input_key)
      end

      GraphQL::Query::Arguments.new(input_values, argument_definitions: arguments)
    end

    def coerce_result(value)
      # Allow the application to provide values as :symbols, and convert them to the strings
      value = value.reduce({}) { |memo, (k, v)| memo[k.to_s] = v; memo }

      result = {}

      arguments.each do |input_key, input_field_defn|
        input_value = value[input_key]
        result[input_key] = input_value.nil? ? nil : input_field_defn.type.coerce_result(input_value) if value.key?(input_key)
      end

      result
    end
  end
end
