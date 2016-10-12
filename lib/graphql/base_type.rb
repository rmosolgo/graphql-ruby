module GraphQL
  # The parent for all type classes.
  class BaseType
    include GraphQL::Define::NonNullWithBang
    include GraphQL::Define::InstanceDefinable
    accepts_definitions :name, :description, {
        connection: GraphQL::Define::AssignConnection,
        global_id_field: GraphQL::Define::AssignGlobalIdField,
      }

    lazy_defined_attr_accessor :name, :description

    # @!attribute name
    #   @return [String] the name of this type, must be unique within a Schema

    # @!attribute description
    #  @return [String, nil] a description for this type

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
    def resolve_type(value)
      self
    end

    # Print the human-readable name of this type using the query-string naming pattern
    def to_s
      name
    end

    alias :inspect :to_s

    def valid_input?(value)
      validate_input(value).valid?
    end

    def validate_input(value)
      return GraphQL::Query::InputValidationResult.new if value.nil?
      validate_non_null_input(value)
    end

    def coerce_input(value)
      return nil if value.nil?
      coerce_non_null_input(value)
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

    # Get the default connection type for this object type
    def connection_type
      @connection_type ||= define_connection
    end

    # Define a custom connection type for this object type
    ### Ruby 1.9.3 unofficial support
    # def define_connection(**kwargs, &block)
    def define_connection(kwargs = {}, &block)
      ### Ruby 1.9.3 unofficial support
      # GraphQL::Relay::ConnectionType.create_type(self, **kwargs, &block)
      GraphQL::Relay::ConnectionType.create_type(self, kwargs, &block)
    end

    # Get the default edge type for this object type
    def edge_type
      @edge_type ||= define_edge
    end

    # Define a custom edge type for this object type
    ### Ruby 1.9.3 unofficial support
    # def define_edge(**kwargs, &block)
    def define_edge(kwargs = {}, &block)
      ### Ruby 1.9.3 unofficial support
      # GraphQL::Relay::EdgeType.create_type(self, **kwargs, &block)
      GraphQL::Relay::EdgeType.create_type(self, kwargs, &block)
    end
  end
end
