# frozen_string_literal: true
module GraphQL
  # The parent for all type classes.
  class BaseType
    include GraphQL::Define::NonNullWithBang
    include GraphQL::Define::InstanceDefinable
    accepts_definitions :name, :description,
        :introspection,
        :default_scalar,
        :default_relay,
        {
          connection: GraphQL::Define::AssignConnection,
          global_id_field: GraphQL::Define::AssignGlobalIdField,
        }

    ensure_defined(:name, :description, :introspection?, :default_scalar?)

    def initialize
      @introspection = false
      @default_scalar = false
      @default_relay = false
    end

    def initialize_copy(other)
      super
      # Reset these derived defaults
      @connection_type = nil
      @edge_type = nil
    end

    # @return [String] the name of this type, must be unique within a Schema
    attr_accessor :name

    # @return [String, nil] a description for this type
    attr_accessor :description

    # @return [Boolean] Is this type a predefined introspection type?
    def introspection?
      @introspection
    end

    # @return [Boolean] Is this type a built-in scalar type? (eg, `String`, `Int`)
    def default_scalar?
      @default_scalar
    end

    # @return [Boolean] Is this type a built-in Relay type? (`Node`, `PageInfo`)
    def default_relay?
      @default_relay
    end

    # @api private
    attr_writer :introspection, :default_scalar, :default_relay

    # @param other [GraphQL::BaseType] compare to this object
    # @return [Boolean] are these types equivalent? (incl. non-null, list)
    def ==(other)
      if other.is_a?(GraphQL::BaseType)
        self.to_s == other.to_s
      else
        super
      end
    end

    # If this type is modifying an underlying type,
    # return the underlying type. (Otherwise, return `self`.)
    def unwrap
      self
    end

    # @return [GraphQL::NonNullType] a non-null version of this type
    def to_non_null_type
      GraphQL::NonNullType.new(of_type: self)
    end

    # @return [GraphQL::ListType] a list version of this type
    def to_list_type
      GraphQL::ListType.new(of_type: self)
    end

    module ModifiesAnotherType
      def unwrap
        self.of_type.unwrap
      end
    end

    # Find out which possible type to use for `value`.
    # Returns self if there are no possible types (ie, not Union or Interface)
    def resolve_type(value, ctx)
      self
    end

    # Print the human-readable name of this type using the query-string naming pattern
    def to_s
      name
    end

    alias :inspect :to_s

    def valid_isolated_input?(value)
      valid_input?(value, GraphQL::Query::NullContext)
    end

    def validate_isolated_input(value)
      validate_input(value, GraphQL::Query::NullContext)
    end

    def coerce_isolated_input(value)
      coerce_input(value, GraphQL::Query::NullContext)
    end

    def coerce_isolated_result(value)
      coerce_result(value, GraphQL::Query::NullContext)
    end

    def valid_input?(value, ctx = nil)
      if ctx.nil?
        warn_deprecated_coerce("valid_isolated_input?")
        ctx = GraphQL::Query::NullContext
      end

      validate_input(value, ctx).valid?
    end

    def validate_input(value, ctx = nil)
      if ctx.nil?
        warn_deprecated_coerce("validate_isolated_input")
        ctx = GraphQL::Query::NullContext
      end

      if value.nil?
        GraphQL::Query::InputValidationResult.new
      else
        validate_non_null_input(value, ctx)
      end
    end

    def coerce_input(value, ctx = nil)
      if value.nil?
        nil
      else
        if ctx.nil?
          warn_deprecated_coerce("coerce_isolated_input")
          ctx = GraphQL::Query::NullContext
        end
        coerce_non_null_input(value, ctx)
      end
    end

    def coerce_result(value, ctx)
      raise NotImplementedError
    end

    # Types with fields may override this
    # @param name [String] field name to lookup for this type
    # @return [GraphQL::Field, nil]
    def get_field(name)
      nil
    end

    # During schema definition, types can be defined inside procs or as strings.
    # This function converts it to a type instance
    # @return [GraphQL::BaseType]
    def self.resolve_related_type(type_arg)
      case type_arg
      when Proc
        # lazy-eval it
        type_arg.call
      when String
        # Get a constant by this name
        Object.const_get(type_arg)
      else
        type_arg
      end
    end

    # @return [GraphQL::ObjectType] The default connection type for this object type
    def connection_type
      @connection_type ||= define_connection
    end

    # Define a custom connection type for this object type
    # @return [GraphQL::ObjectType]
    def define_connection(**kwargs, &block)
      GraphQL::Relay::ConnectionType.create_type(self, **kwargs, &block)
    end

    # @return [GraphQL::ObjectType] The default edge type for this object type
    def edge_type
      @edge_type ||= define_edge
    end

    # Define a custom edge type for this object type
    # @return [GraphQL::ObjectType]
    def define_edge(**kwargs, &block)
      GraphQL::Relay::EdgeType.create_type(self, **kwargs, &block)
    end

    # Return a GraphQL string for the type definition
    # @param schema [GraphQL::Schema]
    # @param printer [GraphQL::Schema::Printer]
    # @see {GraphQL::Schema::Printer#initialize for additional options}
    # @return [String] type definition
    def to_definition(schema, printer: nil, **args)
      printer ||= GraphQL::Schema::Printer.new(schema, **args)
      printer.print_type(self)
    end

    private

    def warn_deprecated_coerce(alt_method_name)
      warn("Coercing without a context is deprecated; use `#{alt_method_name}` if you don't want context-awareness")
    end
  end
end
