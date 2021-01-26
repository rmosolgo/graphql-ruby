# frozen_string_literal: true
require "graphql/relay/type_extensions"

module GraphQL
  # The parent for all type classes.
  class BaseType
    include GraphQL::Define::NonNullWithBang
    include GraphQL::Define::InstanceDefinable
    include GraphQL::Relay::TypeExtensions

    accepts_definitions :name, :description,
        :introspection,
        :default_scalar,
        :default_relay,
        {
          connection: GraphQL::Define::AssignConnection,
          global_id_field: GraphQL::Define::AssignGlobalIdField,
        }

    ensure_defined(:graphql_name, :name, :description, :introspection?, :default_scalar?)

    attr_accessor :ast_node

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
    attr_reader :name
    # Future-compatible alias
    # @see {GraphQL::SchemaMember}
    alias :graphql_name :name
    # Future-compatible alias
    # @see {GraphQL::SchemaMember}
    alias :graphql_definition :itself

    def type_class
      metadata[:type_class]
    end

    def name=(name)
      GraphQL::NameValidator.validate!(name)
      @name = name
    end

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
    # @see {ModifiesAnotherType#==} for override on List & NonNull types
    def ==(other)
      other.is_a?(GraphQL::BaseType) && self.name == other.name
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

      def ==(other)
        other.is_a?(ModifiesAnotherType) && other.of_type == of_type
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
    alias :to_type_signature :to_s

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
      raise GraphQL::RequiredImplementationMissingError
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
        # lazy-eval it, then try again
        resolve_related_type(type_arg.call)
      when String
        # Get a constant by this name
        resolve_related_type(Object.const_get(type_arg))
      else
        if type_arg.respond_to?(:graphql_definition)
          type_arg.graphql_definition
        else
          type_arg
        end
      end
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

    # Returns true if this is a non-nullable type. A nullable list of non-nullables is considered nullable.
    def non_null?
      false
    end

    # Returns true if this is a list type. A non-nullable list is considered a list.
    def list?
      false
    end

    private

    def warn_deprecated_coerce(alt_method_name)
      GraphQL::Deprecation.warn("Coercing without a context is deprecated; use `#{alt_method_name}` if you don't want context-awareness")
    end
  end
end
