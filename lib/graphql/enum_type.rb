# frozen_string_literal: true
module GraphQL
  # @api deprecated
  class EnumType < GraphQL::BaseType
    extend Define::InstanceDefinable::DeprecatedDefine

    accepts_definitions :values, value: GraphQL::Define::AssignEnumValue
    ensure_defined(:values, :validate_non_null_input, :coerce_non_null_input, :coerce_result)
    attr_accessor :ast_node

    def initialize
      super
      @values_by_name = {}
    end

    def initialize_copy(other)
      super
      self.values = other.values.values
    end

    # @param new_values [Array<EnumValue>] The set of values contained in this type
    def values=(new_values)
      @values_by_name = {}
      new_values.each { |enum_value| add_value(enum_value) }
    end

    # @param enum_value [EnumValue] A value to add to this type's set of values
    def add_value(enum_value)
      if @values_by_name.key?(enum_value.name)
        raise "Enum value names must be unique. Value `#{enum_value.name}` already exists on Enum `#{name}`."
      end

      @values_by_name[enum_value.name] = enum_value
    end

    # @return [Hash<String => EnumValue>] `{name => value}` pairs contained in this type
    def values
      @values_by_name
    end

    def kind
      GraphQL::TypeKinds::ENUM
    end

    def coerce_result(value, ctx = nil)
      if ctx.nil?
        warn_deprecated_coerce("coerce_isolated_result")
        ctx = GraphQL::Query::NullContext
      end

      warden = ctx.warden
      all_values = warden ? warden.enum_values(self) : @values_by_name.each_value
      enum_value = all_values.find { |val| val.value == value }
      if enum_value
        enum_value.name
      else
        raise(UnresolvedValueError, "Can't resolve enum #{name} for #{value.inspect}")
      end
    end

    def to_s
      name
    end

    # A value within an {EnumType}
    #
    # Created with the `value` helper
    class EnumValue
      include GraphQL::Define::InstanceDefinable
      ATTRIBUTES = [:name, :description, :deprecation_reason, :value]
      accepts_definitions(*ATTRIBUTES)
      attr_accessor(*ATTRIBUTES)
      attr_accessor :ast_node
      ensure_defined(*ATTRIBUTES)

      undef name=
      def name=(new_name)
        # Validate that the name is correct
        GraphQL::NameValidator.validate!(new_name)
        @name = new_name
      end

      def graphql_name
        name
      end

      def type_class
        metadata[:type_class]
      end
    end

    class UnresolvedValueError < GraphQL::Error
    end

    private

    # Get the underlying value for this enum value
    #
    # @example get episode value from Enum
    #   episode = EpisodeEnum.coerce("NEWHOPE")
    #   episode # => 6
    #
    # @param value_name [String] the string representation of this enum value
    # @return [Object] the underlying value for this enum value
    def coerce_non_null_input(value_name, ctx)
      if @values_by_name.key?(value_name)
        @values_by_name.fetch(value_name).value
      elsif match_by_value = @values_by_name.find { |k, v| v.value == value_name }
        # this is for matching default values, which are "inputs", but they're
        # the Ruby value, not the GraphQL string.
        match_by_value[1].value
      else
        nil
      end
    end

    def validate_non_null_input(value_name, ctx)
      result = GraphQL::Query::InputValidationResult.new
      allowed_values = ctx.warden.enum_values(self)
      matching_value = allowed_values.find { |v| v.name == value_name }

      if matching_value.nil?
        result.add_problem("Expected #{GraphQL::Language.serialize(value_name)} to be one of: #{allowed_values.map(&:name).join(', ')}")
      end

      result
    end
  end
end
