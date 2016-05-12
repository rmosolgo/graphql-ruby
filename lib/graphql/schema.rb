module GraphQL
  # A GraphQL schema which may be queried with {GraphQL::Query}.
  class Schema
    extend Forwardable

    DIRECTIVES = [GraphQL::Directive::SkipDirective, GraphQL::Directive::IncludeDirective]
    DYNAMIC_FIELDS = ["__type", "__typename", "__schema"]

    attr_reader :query, :mutation, :subscription, :directives, :static_validator
    attr_accessor :max_depth
    # Override these if you don't want the default executor:
    attr_accessor :query_execution_strategy,
      :mutation_execution_strategy,
      :subscription_execution_strategy

    # @return [Array<#call>] Middlewares suitable for MiddlewareChain, applied to fields during execution
    attr_reader :middleware

    # @return [GraphQL::QueryCache] The default {QueryCache} instance for this schema
    attr_reader :query_cache

    # @param query [GraphQL::ObjectType]  the query root for the schema
    # @param mutation [GraphQL::ObjectType] the mutation root for the schema
    # @param subscription [GraphQL::ObjectType] the subscription root for the schema
    # @param max_depth [Integer] maximum query nesting (if it's greater, raise an error)
    # @param types [Array<GraphQL::BaseType>] additional types to include in this schema
    def initialize(query:, mutation: nil, subscription: nil, max_depth: nil, types: [])
      @query    = query
      @mutation = mutation
      @subscription = subscription
      @max_depth = max_depth
      @orphan_types = types
      @query_cache = GraphQL::QueryCache.new(self)
      @directives = DIRECTIVES.reduce({}) { |m, d| m[d.name] = d; m }
      @static_validator = GraphQL::StaticValidation::Validator.new(schema: self)
      @rescue_middleware = GraphQL::Schema::RescueMiddleware.new
      @middleware = [@rescue_middleware]
      # Default to the built-in execution strategy:
      self.query_execution_strategy = GraphQL::Query::SerialExecution
      self.mutation_execution_strategy = GraphQL::Query::SerialExecution
      self.subscription_execution_strategy = GraphQL::Query::SerialExecution
    end

    def_delegators :@rescue_middleware, :rescue_from, :remove_handler

    # @return [GraphQL::Schema::TypeMap] `{ name => type }` pairs of types in this schema
    def types
      @types ||= begin
        all_types = @orphan_types + [query, mutation, GraphQL::Introspection::SchemaType]
        TypeReducer.find_all(all_types.compact)
      end
    end


    # Execute a query on itself from string _or_ from cache.
    # See {Query#initialize} for arguments.
    #
    # @example Execute a query from string
    #   MySchema.execute("{ viewer { name } }", context: {user: current_user})
    #
    # @example Execute an operation from the {QueryCache}
    #   MySchema.execute(operation_name: "productInfo", variables: {"id" => 1})
    #
    # @return [Hash] query result, ready to be serialized as JSON
    def execute(query_string = nil, context: nil, variables: {}, debug: false, validate: true, operation_name: nil)
      if query_string.nil?
        query_cache.execute(operation_name, context: context, variables: variables)
      else
        query = GraphQL::Query.new(self, query_string, debug: debug, validate: validate)
        query.execute(context: context, variables: variables, operation_name: operation_name)
      end
    end

    # Resolve field named `field_name` for type `parent_type`.
    # Handles dynamic fields `__typename`, `__type` and `__schema`, too
    def get_field(parent_type, field_name)
      defined_field = parent_type.get_field(field_name)
      if defined_field
        defined_field
      elsif field_name == "__typename"
        GraphQL::Introspection::TypenameField.create(parent_type)
      elsif field_name == "__schema" && parent_type == query
        GraphQL::Introspection::SchemaField.create(self)
      elsif field_name == "__type" && parent_type == query
        GraphQL::Introspection::TypeByNameField.create(self.types)
      else
        nil
      end
    end

    def type_from_ast(ast_node)
      GraphQL::Schema::TypeExpression.new(self, ast_node).type
    end

    # @param type_defn [GraphQL::InterfaceType, GraphQL::UnionType] the type whose members you want to retrieve
    # @return [Array<GraphQL::ObjectType>] types which belong to `type_defn` in this schema
    def possible_types(type_defn)
      @interface_possible_types ||= GraphQL::Schema::PossibleTypes.new(self)
      @interface_possible_types.possible_types(type_defn)
    end

    # Add operations from `query_string` into the {QueryCache}. They can be executed by name later.
    # @param query_string [String] the GraphQL query whose operations will be cached
    def cache(query_string)
      query_cache.add(query_string)
    end

    class InvalidTypeError < GraphQL::Error
      def initialize(type, name)
        super("#{name} has an invalid type: must be an instance of GraphQL::BaseType, not #{type.class.inspect} (#{type.inspect})")
      end
    end
  end
end

require "graphql/schema/each_item_validator"
require "graphql/schema/field_validator"
require "graphql/schema/implementation_validator"
require "graphql/schema/middleware_chain"
require "graphql/schema/rescue_middleware"
require "graphql/schema/possible_types"
require "graphql/schema/type_expression"
require "graphql/schema/type_reducer"
require "graphql/schema/type_map"
require "graphql/schema/type_validator"
