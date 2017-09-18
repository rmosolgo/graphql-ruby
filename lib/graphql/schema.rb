# frozen_string_literal: true
require "graphql/schema/base_64_encoder"
require "graphql/schema/catchall_middleware"
require "graphql/schema/default_parse_error"
require "graphql/schema/default_type_error"
require "graphql/schema/invalid_type_error"
require "graphql/schema/middleware_chain"
require "graphql/schema/null_mask"
require "graphql/schema/possible_types"
require "graphql/schema/rescue_middleware"
require "graphql/schema/timeout_middleware"
require "graphql/schema/traversal"
require "graphql/schema/type_expression"
require "graphql/schema/unique_within_type"
require "graphql/schema/validation"
require "graphql/schema/warden"
require "graphql/schema/build_from_definition"

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
      :max_depth, :max_complexity, :default_max_page_size,
      :orphan_types, :resolve_type, :type_error, :parse_error,
      :raise_definition_error,
      :object_from_id, :id_from_object,
      :default_mask,
      :cursor_encoder,
      directives: ->(schema, directives) { schema.directives = directives.reduce({}) { |m, d| m[d.name] = d; m  }},
      instrument: ->(schema, type, instrumenter, after_built_ins: false) {
        if type == :field && after_built_ins
          type = :field_after_built_ins
        end
        schema.instrumenters[type] << instrumenter
      },
      query_analyzer: ->(schema, analyzer) { schema.query_analyzers << analyzer },
      multiplex_analyzer: ->(schema, analyzer) { schema.multiplex_analyzers << analyzer },
      middleware: ->(schema, middleware) { schema.middleware << middleware },
      lazy_resolve: ->(schema, lazy_class, lazy_value_method) { schema.lazy_methods.set(lazy_class, lazy_value_method) },
      rescue_from: ->(schema, err_class, &block) { schema.rescue_from(err_class, &block)}

    attr_accessor \
      :query, :mutation, :subscription,
      :query_execution_strategy, :mutation_execution_strategy, :subscription_execution_strategy,
      :max_depth, :max_complexity, :default_max_page_size,
      :orphan_types, :directives,
      :query_analyzers, :multiplex_analyzers, :instrumenters, :lazy_methods,
      :cursor_encoder,
      :raise_definition_error

    # Single, long-lived instance of the provided subscriptions class, if there is one.
    # @return [GraphQL::Subscriptions]
    attr_accessor :subscriptions

    # @return [MiddlewareChain] MiddlewareChain which is applied to fields during execution
    attr_accessor :middleware

    # @return [<#call(member, ctx)>] A callable for filtering members of the schema
    # @see {Query.new} for query-specific filters with `except:`
    attr_accessor :default_mask

    class << self
      attr_accessor :default_execution_strategy
    end

    def default_filter
      GraphQL::Filter.new(except: default_mask)
    end

    self.default_execution_strategy = GraphQL::Execution::Execute

    BUILT_IN_TYPES = Hash[[INT_TYPE, STRING_TYPE, FLOAT_TYPE, BOOLEAN_TYPE, ID_TYPE].map{ |type| [type.name, type] }]
    DIRECTIVES = [GraphQL::Directive::IncludeDirective, GraphQL::Directive::SkipDirective, GraphQL::Directive::DeprecatedDirective]
    DYNAMIC_FIELDS = ["__type", "__typename", "__schema"]

    attr_reader :static_validator, :object_from_id_proc, :id_from_object_proc, :resolve_type_proc

    def initialize
      @definition_error = nil
      @orphan_types = []
      @directives = DIRECTIVES.reduce({}) { |m, d| m[d.name] = d; m }
      @static_validator = GraphQL::StaticValidation::Validator.new(schema: self)
      @middleware = MiddlewareChain.new(final_step: GraphQL::Execution::Execute::FieldResolveStep)
      @query_analyzers = []
      @multiplex_analyzers = []
      @resolve_type_proc = nil
      @object_from_id_proc = nil
      @id_from_object_proc = nil
      @type_error_proc = DefaultTypeError
      @parse_error_proc = DefaultParseError
      @instrumenters = Hash.new { |h, k| h[k] = [] }
      @lazy_methods = GraphQL::Execution::Lazy::LazyMethodMap.new
      @lazy_methods.set(GraphQL::Relay::ConnectionResolve::LazyNodesWrapper, :never_called)
      @cursor_encoder = Base64Encoder
      # Default to the built-in execution strategy:
      @query_execution_strategy = self.class.default_execution_strategy
      @mutation_execution_strategy = self.class.default_execution_strategy
      @subscription_execution_strategy = self.class.default_execution_strategy
      @default_mask = GraphQL::Schema::NullMask
      @rebuilding_artifacts = false
    end

    def initialize_copy(other)
      super
      @orphan_types = other.orphan_types.dup
      @directives = other.directives.dup
      @static_validator = GraphQL::StaticValidation::Validator.new(schema: self)
      @middleware = other.middleware.dup
      @query_analyzers = other.query_analyzers.dup
      @multiplex_analyzers = other.multiplex_analyzers.dup

      @possible_types = GraphQL::Schema::PossibleTypes.new(self)

      @lazy_methods = other.lazy_methods.dup

      @instrumenters = Hash.new { |h, k| h[k] = [] }
      other.instrumenters.each do |key, insts|
        @instrumenters[key].concat(insts)
      end

      if other.rescues?
        @rescue_middleware = other.rescue_middleware
      end

      # This will be rebuilt when it's requested
      # or during a later `define` call
      @types = nil
    end

    def rescue_from(*args, &block)
      rescue_middleware.rescue_from(*args, &block)
    end

    def remove_handler(*args, &block)
      rescue_middleware.remove_handler(*args, &block)
    end

    # Validate a query string according to this schema.
    # @param string_or_document [String, GraphQL::Language::Nodes::Document]
    # @return [Array<GraphQL::StaticValidation::Message>]
    def validate(string_or_document, rules: nil)
      doc = if string_or_document.is_a?(String)
        GraphQL.parse(string_or_document)
      else
        string_or_document
      end
      query = GraphQL::Query.new(self, document: doc)
      validator_opts = { schema: self }
      rules && (validator_opts[:rules] = rules)
      validator = GraphQL::StaticValidation::Validator.new(validator_opts)
      res = validator.validate(query)
      res[:errors]
    end

    def define(**kwargs, &block)
      super
      ensure_defined
      # Assert that all necessary configs are present:
      validation_error = Validation.validate(self)
      validation_error && raise(NotImplementedError, validation_error)
      rebuild_artifacts

      @definition_error = nil
      nil
    rescue StandardError => err
      if @raise_definition_error || err.is_a?(CyclicalDefinitionError)
        raise
      else
        # Raise this error _later_ to avoid messing with Rails constant loading
        @definition_error = err
      end
      nil
    end

    # Attach `instrumenter` to this schema for instrumenting events of `instrumentation_type`.
    # @param instrumentation_type [Symbol]
    # @param instrumenter
    # @return [void]
    def instrument(instrumentation_type, instrumenter)
      @instrumenters[instrumentation_type] << instrumenter
      if instrumentation_type == :field
        rebuild_artifacts
      end
    end

    # @return [Array<GraphQL::BaseType>] The root types of this schema
    def root_types
      @root_types ||= begin
        rebuild_artifacts
        @root_types
      end
    end

    # @see [GraphQL::Schema::Warden] Restricted access to members of a schema
    # @return [GraphQL::Schema::TypeMap] `{ name => type }` pairs of types in this schema
    def types
      @types ||= begin
        rebuild_artifacts
        @types
      end
    end

    # Returns a list of Arguments and Fields referencing a certain type
    # @param type_name [String]
    # @return [Hash]
    def references_to(type_name)
      rebuild_artifacts unless defined?(@type_reference_map)
      @type_reference_map.fetch(type_name, [])
    end

    # Returns a list of Union types in which a type is a member
    # @param type [GraphQL::ObjectType]
    # @return [Array<GraphQL::UnionType>] list of union types of which the type is a member
    def union_memberships(type)
      rebuild_artifacts unless defined?(@union_memberships)
      @union_memberships.fetch(type.name, [])
    end

    # Execute a query on itself. Raises an error if the schema definition is invalid.
    # @see {Query#initialize} for arguments.
    # @return [Hash] query result, ready to be serialized as JSON
    def execute(query_str = nil, **kwargs)
      if query_str
        kwargs[:query] = query_str
      end
      # Since we're running one query, don't run a multiplex-level complexity analyzer
      all_results = multiplex([kwargs], max_complexity: nil)
      all_results[0]
    end

    # Execute several queries on itself. Raises an error if the schema definition is invalid.
    # @example Run several queries at once
    #   context = { ... }
    #   queries = [
    #     { query: params[:query_1], variables: params[:variables_1], context: context },
    #     { query: params[:query_2], variables: params[:variables_2], context: context },
    #   ]
    #   results = MySchema.multiplex(queries)
    #   render json: {
    #     result_1: results[0],
    #     result_2: results[1],
    #   }
    #
    # @see {Query#initialize} for query keyword arguments
    # @see {Execution::Multiplex#run_queries} for multiplex keyword arguments
    # @param queries [Array<Hash>] Keyword arguments for each query
    # @param context [Hash] Multiplex-level context
    # @return [Array<Hash>] One result for each query in the input
    def multiplex(queries, **kwargs)
      with_definition_error_check {
        GraphQL::Execution::Multiplex.run_all(self, queries, **kwargs)
      }
    end

    # Resolve field named `field_name` for type `parent_type`.
    # Handles dynamic fields `__typename`, `__type` and `__schema`, too
    # @param parent_type [String, GraphQL::BaseType]
    # @param field_name [String]
    # @return [GraphQL::Field, nil] The field named `field_name` on `parent_type`
    # @see [GraphQL::Schema::Warden] Restricted access to members of a schema
    def get_field(parent_type, field_name)
      with_definition_error_check do
        parent_type_name = case parent_type
        when GraphQL::BaseType
          parent_type.name
        when String
          parent_type
        else
          raise "Unexpected parent_type: #{parent_type}"
        end

        defined_field = @instrumented_field_map[parent_type_name][field_name]
        if defined_field
          defined_field
        elsif field_name == "__typename"
          GraphQL::Introspection::TypenameField
        elsif field_name == "__schema" && parent_type == query
          GraphQL::Introspection::SchemaField
        elsif field_name == "__type" && parent_type == query
          GraphQL::Introspection::TypeByNameField
        else
          nil
        end
      end
    end

    # Fields for this type, after instrumentation is applied
    # @return [Hash<String, GraphQL::Field>]
    def get_fields(type)
      @instrumented_field_map[type.name]
    end

    def type_from_ast(ast_node)
      GraphQL::Schema::TypeExpression.build_type(self.types, ast_node)
    end

    # @see [GraphQL::Schema::Warden] Restricted access to members of a schema
    # @param type_defn [GraphQL::InterfaceType, GraphQL::UnionType] the type whose members you want to retrieve
    # @return [Array<GraphQL::ObjectType>] types which belong to `type_defn` in this schema
    def possible_types(type_defn)
      @possible_types ||= GraphQL::Schema::PossibleTypes.new(self)
      @possible_types.possible_types(type_defn)
    end

    # @see [GraphQL::Schema::Warden] Resticted access to root types
    # @return [GraphQL::ObjectType, nil]
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
    # This is required for unions and interfaces (including Relay's `Node` interface)
    # @see [GraphQL::Schema::Warden] Restricted access to members of a schema
    # @param type [GraphQL::UnionType, GraphQL:InterfaceType] the abstract type which is being resolved
    # @param object [Any] An application object which GraphQL is currently resolving on
    # @param ctx [GraphQL::Query::Context] The context for the current query
    # @return [GraphQL::ObjectType] The type for exposing `object` in GraphQL
    def resolve_type(type, object, ctx = :__undefined__)
      if ctx == :__undefined__
        # Old method signature
        ctx = object
        object = type
        type = nil
      end

      # Prefer a type-local function; fall back to the schema-level function
      type_proc = type && type.resolve_type_proc
      type_result = if type_proc
        type_proc.call(object, ctx)
      else
        if @resolve_type_proc.nil?
          raise(NotImplementedError, "Can't determine GraphQL type for: #{object.inspect}, define `resolve_type (type, obj, ctx) -> { ... }` inside `Schema.define`.")
        end
        @resolve_type_proc.call(type, object, ctx)
      end

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
      callable = GraphQL::BackwardsCompatibility.wrap_arity(new_resolve_type_proc, from: 2, to: 3, last: true, name: "Schema#resolve_type(type, obj, ctx)")
      @resolve_type_proc = callable
    end

    # Fetch an application object by its unique id
    # @param id [String] A unique identifier, provided previously by this GraphQL schema
    # @param ctx [GraphQL::Query::Context] The context for the current query
    # @return [Any] The application object identified by `id`
    def object_from_id(id, ctx)
      if @object_from_id_proc.nil?
        raise(NotImplementedError, "Can't fetch an object for id \"#{id}\" because the schema's `object_from_id (id, ctx) -> { ... }` function is not defined")
      else
        @object_from_id_proc.call(id, ctx)
      end
    end

    # @param new_proc [#call] A new callable for fetching objects by ID
    def object_from_id=(new_proc)
      @object_from_id_proc = new_proc
    end

    # When we encounter a type error during query execution, we call this hook.
    #
    # You can use this hook to write a log entry,
    # add a {GraphQL::ExecutionError} to the response (with `ctx.add_error`)
    # or raise an exception and halt query execution.
    #
    # @example A `nil` is encountered by a non-null field
    #   type_error ->(err, query_ctx) {
    #     err.is_a?(GraphQL::InvalidNullError) # => true
    #   }
    #
    # @example An object doesn't resolve to one of a {UnionType}'s members
    #   type_error ->(err, query_ctx) {
    #     err.is_a?(GraphQL::UnresolvedTypeError) # => true
    #   }
    #
    # @see {DefaultTypeError} is the default behavior.
    # @param err [GraphQL::TypeError] The error encountered during execution
    # @param ctx [GraphQL::Query::Context] The context for the field where the error occurred
    # @return void
    def type_error(err, ctx)
      @type_error_proc.call(err, ctx)
    end

    # @param new_proc [#call] A new callable for handling type errors during execution
    def type_error=(new_proc)
      @type_error_proc = new_proc
    end

    # A function to call when {#execute} receives an invalid query string
    #
    # @see {DefaultParseError} is the default behavior.
    # @param err [GraphQL::ParseError] The error encountered during parsing
    # @param ctx [GraphQL::Query::Context] The context for the query where the error occurred
    # @return void
    def parse_error(err, ctx)
      @parse_error_proc.call(err, ctx)
    end

    # @param new_proc [#call] A new callable for handling parse errors during execution
    def parse_error=(new_proc)
      @parse_error_proc = new_proc
    end

    # Get a unique identifier from this object
    # @param object [Any] An application object
    # @param type [GraphQL::BaseType] The current type definition
    # @param ctx [GraphQL::Query::Context] the context for the current query
    # @return [String] a unique identifier for `object` which clients can use to refetch it
    def id_from_object(object, type, ctx)
      if @id_from_object_proc.nil?
        raise(NotImplementedError, "Can't generate an ID for #{object.inspect} of type #{type}, schema's `id_from_object` must be defined")
      else
        @id_from_object_proc.call(object, type, ctx)
      end
    end

    # @param new_proc [#call] A new callable for generating unique IDs
    def id_from_object=(new_proc)
      @id_from_object_proc = new_proc
    end

    # Create schema with the result of an introspection query.
    # @param introspection_result [Hash] A response from {GraphQL::Introspection::INTROSPECTION_QUERY}
    # @return [GraphQL::Schema] the schema described by `input`
    def self.from_introspection(introspection_result)
      GraphQL::Schema::Loader.load(introspection_result)
    end

    # Create schema from an IDL schema or file containing an IDL definition.
    # @param definition_or_path [String] A schema definition string, or a path to a file containing the definition
    # @param default_resolve [<#call(type, field, obj, args, ctx)>] A callable for handling field resolution
    # @param parser [Object] An object for handling definition string parsing (must respond to `parse`)
    # @return [GraphQL::Schema] the schema described by `document`
    def self.from_definition(definition_or_path, default_resolve: BuildFromDefinition::DefaultResolve, parser: BuildFromDefinition::DefaultParser)
      # If the file ends in `.graphql`, treat it like a filepath
      definition = if definition_or_path.end_with?(".graphql")
        File.read(definition_or_path)
      else
        definition_or_path
      end
      GraphQL::Schema::BuildFromDefinition.from_definition(definition, default_resolve: default_resolve, parser: parser)
    end

    # Error that is raised when [#Schema#from_definition] is passed an invalid schema definition string.
    class InvalidDocumentError < Error; end;

    # @return [Symbol, nil] The method name to lazily resolve `obj`, or nil if `obj`'s class wasn't registered wtih {#lazy_resolve}.
    def lazy_method_name(obj)
      @lazy_methods.get(obj)
    end

    # @return [Boolean] True if this object should be lazily resolved
    def lazy?(obj)
      !!lazy_method_name(obj)
    end

    # Return the GraphQL IDL for the schema
    # @param context [Hash]
    # @param only [<#call(member, ctx)>]
    # @param except [<#call(member, ctx)>]
    # @return [String]
    def to_definition(only: nil, except: nil, context: {})
      GraphQL::Schema::Printer.print_schema(self, only: only, except: except, context: context)
    end

    # Return the Hash response of {Introspection::INTROSPECTION_QUERY}.
    # @param context [Hash]
    # @param only [<#call(member, ctx)>]
    # @param except [<#call(member, ctx)>]
    # @return [Hash] GraphQL result
    def as_json(only: nil, except: nil, context: {})
      execute(Introspection::INTROSPECTION_QUERY, only: only, except: except, context: context)
    end

    # Returns the JSON response of {Introspection::INTROSPECTION_QUERY}.
    # @see {#as_json}
    # @return [String]
    def to_json(*args)
      JSON.pretty_generate(as_json(*args))
    end

    protected

    def rescues?
      !!@rescue_middleware
    end

    # Lazily create a middleware and add it to the schema
    # (Don't add it if it's not used)
    def rescue_middleware
      @rescue_middleware ||= GraphQL::Schema::RescueMiddleware.new.tap { |m| middleware.insert(0, m) }
    end

    private

    # Wrap Relay-related objects in wrappers
    # @api private
    BUILT_IN_INSTRUMENTERS = [
      GraphQL::Relay::ConnectionInstrumentation,
      GraphQL::Relay::EdgesInstrumentation,
      GraphQL::Relay::Mutation::Instrumentation,
    ]

    def rebuild_artifacts
      if @rebuilding_artifacts
        raise CyclicalDefinitionError, "Part of the schema build process re-triggered the schema build process, causing an infinite loop. Avoid using Schema#types, Schema#possible_types, and Schema#get_field during schema build."
      else
        @rebuilding_artifacts = true
        traversal = Traversal.new(self)
        @types = traversal.type_map
        @root_types = [query, mutation, subscription]
        @instrumented_field_map = traversal.instrumented_field_map
        @type_reference_map = traversal.type_reference_map
        @union_memberships = traversal.union_memberships
      end
    ensure
      @rebuilding_artifacts = false
    end

    class CyclicalDefinitionError < GraphQL::Error
    end

    def with_definition_error_check
      if @definition_error
        raise @definition_error
      else
        yield
      end
    end
  end
end
