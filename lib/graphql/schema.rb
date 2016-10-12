require "graphql/schema/catchall_middleware"
require "graphql/schema/invalid_type_error"
require "graphql/schema/middleware_chain"
require "graphql/schema/possible_types"
require "graphql/schema/rescue_middleware"
require "graphql/schema/reduce_types"
require "graphql/schema/timeout_middleware"
require "graphql/schema/type_expression"
require "graphql/schema/type_map"
require "graphql/schema/unique_within_type"
require "graphql/schema/validation"

module GraphQL
  # A GraphQL schema which may be queried with {GraphQL::Query}.
  #
  # The {Schema} contains:
  #
  #  - types for exposing your application
  #  - query analyzers for assessing incoming queries (including max depth & max complexity restrictions)
  #  - execution strategies for running incoming queries
  #  - middleware for interacting with execution
  #
  # Schemas start with root types, {Schema#query}, {Schema#mutation} and {Schema#subscription}.
  # The schema will traverse the tree of fields & types, using those as starting points.
  # Any undiscoverable types may be provided with the `types` configuration.
  #
  # Schemas can restrict large incoming queries with `max_depth` and `max_complexity` configurations.
  # (These configurations can be overridden by specific calls to {Schema#execute})
  #
  # Schemas can specify how queries should be executed against them.
  # `query_execution_strategy`, `mutation_execution_strategy` and `subscription_execution_strategy`
  # each apply to corresponding root types.
  #
  # A schema accepts a `Relay::GlobalNodeIdentification` instance for use with Relay IDs.
  #
  # @example defining a schema
  #   MySchema = GraphQL::Schema.define do
  #     query QueryType
  #     middleware PermissionMiddleware
  #     rescue_from(ActiveRecord::RecordNotFound) { "Not found" }
  #     # If types are only connected by way of interfaces, they must be added here
  #     orphan_types ImageType, AudioType
  #   end
  #
  class Schema
    include GraphQL::Define::InstanceDefinable
    accepts_definitions \
      :query, :mutation, :subscription,
      :query_execution_strategy, :mutation_execution_strategy, :subscription_execution_strategy,
      :max_depth, :max_complexity,
      :orphan_types, :resolve_type,
      :object_from_id, :id_from_object,
      query_analyzer: ->(schema, analyzer) { schema.query_analyzers << analyzer },
      middleware: ->(schema, middleware) { schema.middleware << middleware },
      rescue_from: ->(schema, err_class, &block) { schema.rescue_from(err_class, &block)}

    lazy_defined_attr_accessor \
      :query, :mutation, :subscription,
      :query_execution_strategy, :mutation_execution_strategy, :subscription_execution_strategy,
      :max_depth, :max_complexity,
      :orphan_types,
      :query_analyzers, :middleware

    DIRECTIVES = [GraphQL::Directive::SkipDirective, GraphQL::Directive::IncludeDirective, GraphQL::Directive::DeprecatedDirective]
    DYNAMIC_FIELDS = ["__type", "__typename", "__schema"]

    attr_reader :directives, :static_validator, :object_from_id_proc, :id_from_object_proc, :resolve_type_proc

    # @!attribute [r] middleware
    #   @return [Array<#call>] Middlewares suitable for MiddlewareChain, applied to fields during execution

    # @param query [GraphQL::ObjectType]  the query root for the schema
    # @param mutation [GraphQL::ObjectType] the mutation root for the schema
    # @param subscription [GraphQL::ObjectType] the subscription root for the schema
    # @param max_depth [Integer] maximum query nesting (if it's greater, raise an error)
    # @param types [Array<GraphQL::BaseType>] additional types to include in this schema
    def initialize(query: nil, mutation: nil, subscription: nil, max_depth: nil, max_complexity: nil, types: [])
      if query
        warn("Schema.new is deprecated, use Schema.define instead")
      end
      @query    = query
      @mutation = mutation
      @subscription = subscription
      @max_depth = max_depth
      @max_complexity = max_complexity
      @orphan_types = types
      @directives = DIRECTIVES.reduce({}) { |m, d| m[d.name] = d; m }
      @static_validator = GraphQL::StaticValidation::Validator.new(schema: self)
      @rescue_middleware = GraphQL::Schema::RescueMiddleware.new
      @middleware = [@rescue_middleware]
      @query_analyzers = []
      @resolve_type_proc = nil
      @object_from_id_proc = nil
      @id_from_object_proc = nil
      # Default to the built-in execution strategy:
      @query_execution_strategy = GraphQL::Query::SerialExecution
      @mutation_execution_strategy = GraphQL::Query::SerialExecution
      @subscription_execution_strategy = GraphQL::Query::SerialExecution
    end

    def rescue_from(*args, &block)
      ensure_defined
      @rescue_middleware.rescue_from(*args, &block)
    end

    def remove_handler(*args, &block)
      ensure_defined
      @rescue_middleware.remove_handler(*args, &block)
    end

    def define(**kwargs, &block)
      super
      types
      # Assert that all necessary configs are present:
      validation_error = Validation.validate(self)
      validation_error && raise(NotImplementedError, validation_error)
      nil
    end

    # @return [GraphQL::Schema::TypeMap] `{ name => type }` pairs of types in this schema
    def types
      @types ||= begin
        ensure_defined
        all_types = orphan_types + [query, mutation, subscription, GraphQL::Introspection::SchemaType]
        GraphQL::Schema::ReduceTypes.reduce(all_types.compact)
      end
    end

    # Execute a query on itself.
    # See {Query#initialize} for arguments.
    # @return [Hash] query result, ready to be serialized as JSON
    def execute(*args)
      query_obj = GraphQL::Query.new(self, *args)
      query_obj.result
    end

    # Resolve field named `field_name` for type `parent_type`.
    # Handles dynamic fields `__typename`, `__type` and `__schema`, too
    def get_field(parent_type, field_name)
      ensure_defined
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
      ensure_defined
      GraphQL::Schema::TypeExpression.build_type(self, ast_node)
    end

    # TODO: when `resolve_type` is schema level, can this be removed?
    # @param type_defn [GraphQL::InterfaceType, GraphQL::UnionType] the type whose members you want to retrieve
    # @return [Array<GraphQL::ObjectType>] types which belong to `type_defn` in this schema
    def possible_types(type_defn)
      ensure_defined
      @interface_possible_types ||= GraphQL::Schema::PossibleTypes.new(self)
      @interface_possible_types.possible_types(type_defn)
    end

    def root_type_for_operation(operation)
      case operation
      when "query"
        query
      when "mutation"
        mutation
      when "subscription"
        subscription
      else
        raise ArgumentError, "unknown operation type: #{operation}"
      end
    end

    def execution_strategy_for_operation(operation)
      case operation
      when "query"
        query_execution_strategy
      when "mutation"
        mutation_execution_strategy
      when "subscription"
        subscription_execution_strategy
      else
        raise ArgumentError, "unknown operation type: #{operation}"
      end
    end

    # Determine the GraphQL type for a given object.
    # This is required for unions and interfaces (include Relay's node interface)
    # @param object [Any] An application object which GraphQL is currently resolving on
    # @param ctx [GraphQL::Query::Context] The context for the current query
    # @return [GraphQL::ObjectType] The type for exposing `object` in GraphQL
    def resolve_type(object, ctx)
      ensure_defined

      if @resolve_type_proc.nil?
        raise(NotImplementedError, "Can't determine GraphQL type for: #{object.inspect}, define `resolve_type (obj, ctx) -> { ... }` inside `Schema.define`.")
      end

      type_result = @resolve_type_proc.call(object, ctx)
      if type_result.nil?
        nil
      elsif !type_result.is_a?(GraphQL::BaseType)
        type_str = "#{type_result} (#{type_result.class.name})"
        raise "resolve_type(#{object}) returned #{type_str}, but it should return a GraphQL type"
      else
        type_result
      end
    end

    def resolve_type=(new_resolve_type_proc)
      ensure_defined
      @resolve_type_proc = new_resolve_type_proc
    end

    # Fetch an application object by its unique id
    # @param id [String] A unique identifier, provided previously by this GraphQL schema
    # @param ctx [GraphQL::Query::Context] The context for the current query
    # @return [Any] The application object identified by `id`
    def object_from_id(id, ctx)
      ensure_defined
      if @object_from_id_proc.nil?
        raise(NotImplementedError, "Can't fetch an object for id \"#{id}\" because the schema's `object_from_id (id, ctx) -> { ... }` function is not defined")
      else
        @object_from_id_proc.call(id, ctx)
      end
    end

    # @param new_proc [#call] A new callable for fetching objects by ID
    def object_from_id=(new_proc)
      ensure_defined
      @object_from_id_proc = new_proc
    end

    # Get a unique identifier from this object
    # @param object [Any] An application object
    # @param type [GraphQL::BaseType] The current type definition
    # @param ctx [GraphQL::Query::Context] the context for the current query
    # @return [String] a unique identifier for `object` which clients can use to refetch it
    def id_from_object(object, type, ctx)
      ensure_defined
      if @id_from_object_proc.nil?
        raise(NotImplementedError, "Can't generate an ID for #{object.inspect} of type #{type}, schema's `id_from_object` must be defined")
      else
        @id_from_object_proc.call(object, type, ctx)
      end
    end

    # @param new_proc [#call] A new callable for generating unique IDs
    def id_from_object=(new_proc)
      ensure_defined
      @id_from_object_proc = new_proc
    end
  end
end
