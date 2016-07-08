require "graphql/schema/catchall_middleware"
require "graphql/schema/invalid_type_error"
require "graphql/schema/middleware_chain"
require "graphql/schema/rescue_middleware"
require "graphql/schema/possible_types"
require "graphql/schema/reduce_types"
require "graphql/schema/type_expression"
require "graphql/schema/type_map"
require "graphql/schema/validation"

module GraphQL
  # A GraphQL schema which may be queried with {GraphQL::Query}.
  class Schema
    extend Forwardable

    DIRECTIVES = [GraphQL::Directive::SkipDirective, GraphQL::Directive::IncludeDirective]
    DYNAMIC_FIELDS = ["__type", "__typename", "__schema"]

    attr_reader :query, :mutation, :subscription, :directives, :static_validator, :validation_results
    attr_accessor :max_depth
    # Override these if you don't want the default executor:
    attr_accessor :query_execution_strategy,
      :mutation_execution_strategy,
      :subscription_execution_strategy

    # @return [Array<#call>] Middlewares suitable for MiddlewareChain, applied to fields during execution
    attr_reader :middleware

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
      @directives = DIRECTIVES.reduce({}) { |m, d| m[d.name] = d; m }
      @static_validator = GraphQL::StaticValidation::Validator.new(schema: self)
      @rescue_middleware = GraphQL::Schema::RescueMiddleware.new
      @middleware = [@rescue_middleware]
      @validation_results = {}
      # Default to the built-in execution strategy:
      self.query_execution_strategy = GraphQL::Query::SerialExecution
      self.mutation_execution_strategy = GraphQL::Query::SerialExecution
      self.subscription_execution_strategy = GraphQL::Query::SerialExecution
    end

    def_delegators :@rescue_middleware, :rescue_from, :remove_handler

    # @return [GraphQL::Schema::TypeMap] `{ name => type }` pairs of types in this schema
    def types
      @types ||= begin
        all_types = @orphan_types + [query, mutation, subscription, GraphQL::Introspection::SchemaType]
        GraphQL::Schema::ReduceTypes.reduce(all_types.compact)
      end
    end

    # Execute a query on itself.
    # See {Query#initialize} for arguments.
    # @return [Hash] query result, ready to be serialized as JSON
    def execute(*args)
      query = GraphQL::Query.new(self, *args)
      query.result
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
      GraphQL::Schema::TypeExpression.build_type(self, ast_node)
    end

    # @param type_defn [GraphQL::InterfaceType, GraphQL::UnionType] the type whose members you want to retrieve
    # @return [Array<GraphQL::ObjectType>] types which belong to `type_defn` in this schema
    def possible_types(type_defn)
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
  end
end
