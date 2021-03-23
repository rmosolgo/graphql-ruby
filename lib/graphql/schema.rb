# frozen_string_literal: true
require "graphql/schema/base_64_encoder"
require "graphql/schema/catchall_middleware"
require "graphql/schema/default_parse_error"
require "graphql/schema/default_type_error"
require "graphql/schema/find_inherited_value"
require "graphql/schema/finder"
require "graphql/schema/invalid_type_error"
require "graphql/schema/introspection_system"
require "graphql/schema/late_bound_type"
require "graphql/schema/middleware_chain"
require "graphql/schema/null_mask"
require "graphql/schema/possible_types"
require "graphql/schema/rescue_middleware"
require "graphql/schema/timeout"
require "graphql/schema/timeout_middleware"
require "graphql/schema/traversal"
require "graphql/schema/type_expression"
require "graphql/schema/unique_within_type"
require "graphql/schema/validation"
require "graphql/schema/warden"
require "graphql/schema/build_from_definition"

require "graphql/schema/validator"
require "graphql/schema/member"
require "graphql/schema/wrapper"
require "graphql/schema/list"
require "graphql/schema/non_null"
require "graphql/schema/argument"
require "graphql/schema/enum_value"
require "graphql/schema/enum"
require "graphql/schema/field_extension"
require "graphql/schema/field"
require "graphql/schema/input_object"
require "graphql/schema/interface"
require "graphql/schema/scalar"
require "graphql/schema/object"
require "graphql/schema/union"
require "graphql/schema/directive"
require "graphql/schema/directive/deprecated"
require "graphql/schema/directive/include"
require "graphql/schema/directive/skip"
require "graphql/schema/directive/feature"
require "graphql/schema/directive/flagged"
require "graphql/schema/directive/transform"
require "graphql/schema/type_membership"

require "graphql/schema/resolver"
require "graphql/schema/mutation"
require "graphql/schema/relay_classic_mutation"
require "graphql/schema/subscription"

module GraphQL
  # A GraphQL schema which may be queried with {GraphQL::Query}.
  #
  # The {Schema} contains:
  #
  #  - types for exposing your application
  #  - query analyzers for assessing incoming queries (including max depth & max complexity restrictions)
  #  - execution strategies for running incoming queries
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
  #  #
  # @example defining a schema
  #   class MySchema < GraphQL::Schema
  #     query QueryType
  #     # If types are only connected by way of interfaces, they must be added here
  #     orphan_types ImageType, AudioType
  #   end
  #
  class Schema
    extend Forwardable
    extend GraphQL::Schema::Member::AcceptsDefinition
    extend GraphQL::Schema::Member::HasAstNode
    include GraphQL::Define::InstanceDefinable
    extend GraphQL::Define::InstanceDefinable::DeprecatedDefine
    extend GraphQL::Schema::FindInheritedValue

    class DuplicateTypeNamesError < GraphQL::Error
      def initialize(type_name:, first_definition:, second_definition:, path:)
        super("Multiple definitions for `#{type_name}`. Previously found #{first_definition.inspect} (#{first_definition.class}), then found #{second_definition.inspect} (#{second_definition.class}) at #{path.join(".")}")
      end
    end

    class UnresolvedLateBoundTypeError < GraphQL::Error
      attr_reader :type
      def initialize(type:)
        @type = type
        super("Late bound type was never found: #{type.inspect}")
      end
    end

    module LazyHandlingMethods
      # Call the given block at the right time, either:
      # - Right away, if `value` is not registered with `lazy_resolve`
      # - After resolving `value`, if it's registered with `lazy_resolve` (eg, `Promise`)
      # @api private
      def after_lazy(value, &block)
        if lazy?(value)
          GraphQL::Execution::Lazy.new do
            result = sync_lazy(value)
            # The returned result might also be lazy, so check it, too
            after_lazy(result, &block)
          end
        else
          yield(value) if block_given?
        end
      end

      # Override this method to handle lazy objects in a custom way.
      # @param value [Object] an instance of a class registered with {.lazy_resolve}
      # @return [Object] A GraphQL-ready (non-lazy) object
      # @api private
      def sync_lazy(value)
        lazy_method = lazy_method_name(value)
        if lazy_method
          synced_value = value.public_send(lazy_method)
          sync_lazy(synced_value)
        else
          value
        end
      end

      # @return [Symbol, nil] The method name to lazily resolve `obj`, or nil if `obj`'s class wasn't registered with {#lazy_resolve}.
      def lazy_method_name(obj)
        lazy_methods.get(obj)
      end

      # @return [Boolean] True if this object should be lazily resolved
      def lazy?(obj)
        !!lazy_method_name(obj)
      end

      # Return a lazy if any of `maybe_lazies` are lazy,
      # otherwise, call the block eagerly and return the result.
      # @param maybe_lazies [Array]
      # @api private
      def after_any_lazies(maybe_lazies)
        if maybe_lazies.any? { |l| lazy?(l) }
          GraphQL::Execution::Lazy.all(maybe_lazies).then do |result|
            yield result
          end
        else
          yield maybe_lazies
        end
      end
    end

    include LazyHandlingMethods
    extend LazyHandlingMethods

    accepts_definitions \
      :query_execution_strategy, :mutation_execution_strategy, :subscription_execution_strategy,
      :validate_timeout, :max_depth, :max_complexity, :default_max_page_size,
      :orphan_types, :resolve_type, :type_error, :parse_error,
      :error_bubbling,
      :raise_definition_error,
      :object_from_id, :id_from_object,
      :default_mask,
      :cursor_encoder,
      # If these are given as classes, normalize them. Accept `nil` when building from string.
      query: ->(schema, t) { schema.query = t.respond_to?(:graphql_definition) ? t.graphql_definition : t },
      mutation: ->(schema, t) { schema.mutation = t.respond_to?(:graphql_definition) ? t.graphql_definition : t },
      subscription: ->(schema, t) { schema.subscription = t.respond_to?(:graphql_definition) ? t.graphql_definition : t },
      disable_introspection_entry_points: ->(schema) { schema.disable_introspection_entry_points = true },
      disable_schema_introspection_entry_point: ->(schema) { schema.disable_schema_introspection_entry_point = true },
      disable_type_introspection_entry_point: ->(schema) { schema.disable_type_introspection_entry_point = true },
      directives: ->(schema, directives) { schema.directives = directives.reduce({}) { |m, d| m[d.graphql_name] = d; m } },
      directive: ->(schema, directive) { schema.directives[directive.graphql_name] = directive },
      instrument: ->(schema, type, instrumenter, after_built_ins: false) {
        if type == :field && after_built_ins
          type = :field_after_built_ins
        end
        schema.instrumenters[type] << instrumenter
      },
      query_analyzer: ->(schema, analyzer) {
        if analyzer == GraphQL::Authorization::Analyzer
          GraphQL::Deprecation.warn("The Authorization query analyzer is deprecated. Authorizing at query runtime is generally a better idea.")
        end
        schema.query_analyzers << analyzer
      },
      multiplex_analyzer: ->(schema, analyzer) { schema.multiplex_analyzers << analyzer },
      middleware: ->(schema, middleware) { schema.middleware << middleware },
      lazy_resolve: ->(schema, lazy_class, lazy_value_method) { schema.lazy_methods.set(lazy_class, lazy_value_method) },
      rescue_from: ->(schema, err_class, &block) { schema.rescue_from(err_class, &block) },
      tracer: ->(schema, tracer) { schema.tracers.push(tracer) }

    ensure_defined :introspection_system

    attr_accessor \
      :query, :mutation, :subscription,
      :query_execution_strategy, :mutation_execution_strategy, :subscription_execution_strategy,
      :validate_timeout, :max_depth, :max_complexity, :default_max_page_size,
      :orphan_types, :directives,
      :query_analyzers, :multiplex_analyzers, :instrumenters, :lazy_methods,
      :cursor_encoder,
      :ast_node,
      :raise_definition_error,
      :introspection_namespace,
      :analysis_engine

    # [Boolean] True if this object bubbles validation errors up from a field into its parent InputObject, if there is one.
    attr_accessor :error_bubbling

    # Single, long-lived instance of the provided subscriptions class, if there is one.
    # @return [GraphQL::Subscriptions]
    attr_accessor :subscriptions

    # @return [MiddlewareChain] MiddlewareChain which is applied to fields during execution
    attr_accessor :middleware

    # @return [<#call(member, ctx)>] A callable for filtering members of the schema
    # @see {Query.new} for query-specific filters with `except:`
    attr_accessor :default_mask

    # @see {GraphQL::Query::Context} The parent class of these classes
    # @return [Class] Instantiated for each query
    attr_accessor :context_class

    # [Boolean] True if this object disables the introspection entry point fields
    attr_accessor :disable_introspection_entry_points

    def disable_introspection_entry_points?
      !!@disable_introspection_entry_points
    end

    # [Boolean] True if this object disables the __schema introspection entry point field
    attr_accessor :disable_schema_introspection_entry_point

    def disable_schema_introspection_entry_point?
      !!@disable_schema_introspection_entry_point
    end

    # [Boolean] True if this object disables the __type introspection entry point field
    attr_accessor :disable_type_introspection_entry_point

    def disable_type_introspection_entry_point?
      !!@disable_type_introspection_entry_point
    end

    class << self
      attr_writer :default_execution_strategy
    end

    def default_filter
      GraphQL::Filter.new(except: default_mask)
    end

    # @return [Array<#trace(key, data)>] Tracers applied to every query
    # @see {Query#tracers} for query-specific tracers
    attr_reader :tracers

    DYNAMIC_FIELDS = ["__type", "__typename", "__schema"].freeze

    attr_reader :static_validator, :object_from_id_proc, :id_from_object_proc, :resolve_type_proc

    def initialize
      @tracers = []
      @definition_error = nil
      @orphan_types = []
      @directives = {}
      self.class.default_directives.each do |name, dir|
        @directives[name] = dir.graphql_definition
      end
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
      @lazy_methods.set(GraphQL::Execution::Lazy, :value)
      @cursor_encoder = Base64Encoder
      # For schema instances, default to legacy runtime modules
      @analysis_engine = GraphQL::Analysis
      @query_execution_strategy = GraphQL::Execution::Execute
      @mutation_execution_strategy = GraphQL::Execution::Execute
      @subscription_execution_strategy = GraphQL::Execution::Execute
      @default_mask = GraphQL::Schema::NullMask
      @rebuilding_artifacts = false
      @context_class = GraphQL::Query::Context
      @introspection_namespace = nil
      @introspection_system = nil
      @interpreter = false
      @error_bubbling = false
      @disable_introspection_entry_points = false
      @disable_schema_introspection_entry_point = false
      @disable_type_introspection_entry_point = false
    end

    # @return [Boolean] True if using the new {GraphQL::Execution::Interpreter}
    def interpreter?
      query_execution_strategy == GraphQL::Execution::Interpreter &&
        mutation_execution_strategy == GraphQL::Execution::Interpreter &&
        subscription_execution_strategy == GraphQL::Execution::Interpreter
    end

    def inspect
      "#<#{self.class.name} ...>"
    end

    def initialize_copy(other)
      super
      @orphan_types = other.orphan_types.dup
      @directives = other.directives.dup
      @static_validator = GraphQL::StaticValidation::Validator.new(schema: self)
      @middleware = other.middleware.dup
      @query_analyzers = other.query_analyzers.dup
      @multiplex_analyzers = other.multiplex_analyzers.dup
      @tracers = other.tracers.dup
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
      @introspection_system = nil
    end

    def rescue_from(*args, &block)
      rescue_middleware.rescue_from(*args, &block)
    end

    def remove_handler(*args, &block)
      rescue_middleware.remove_handler(*args, &block)
    end

    def using_ast_analysis?
      @analysis_engine == GraphQL::Analysis::AST
    end

    # For forwards-compatibility with Schema classes
    alias :graphql_definition :itself

    # Validate a query string according to this schema.
    # @param string_or_document [String, GraphQL::Language::Nodes::Document]
    # @return [Array<GraphQL::StaticValidation::Error >]
    def validate(string_or_document, rules: nil, context: nil)
      doc = if string_or_document.is_a?(String)
        GraphQL.parse(string_or_document)
      else
        string_or_document
      end
      query = GraphQL::Query.new(self, document: doc, context: context)
      validator_opts = { schema: self }
      rules && (validator_opts[:rules] = rules)
      validator = GraphQL::StaticValidation::Validator.new(**validator_opts)
      res = validator.validate(query, timeout: validate_timeout)
      res[:errors]
    end

    def deprecated_define(**kwargs, &block)
      super
      ensure_defined
      # Assert that all necessary configs are present:
      validation_error = Validation.validate(self)
      validation_error && raise(GraphQL::RequiredImplementationMissingError, validation_error)
      rebuild_artifacts

      @definition_error = nil
      nil
    rescue StandardError => err
      if @raise_definition_error || err.is_a?(CyclicalDefinitionError) || err.is_a?(GraphQL::RequiredImplementationMissingError)
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

    def get_type(type_name)
      @types[type_name]
    end

    # @api private
    def introspection_system
      @introspection_system ||= begin
        rebuild_artifacts
        @introspection_system
      end
    end

    # Returns a list of Arguments and Fields referencing a certain type
    # @param type_name [String]
    # @return [Hash]
    def references_to(type_name = nil)
      rebuild_artifacts unless defined?(@type_reference_map)
      if type_name
        @type_reference_map.fetch(type_name, [])
      else
        @type_reference_map
      end
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
      # Some of the query context _should_ be passed to the multiplex, too
      multiplex_context = if (ctx = kwargs[:context])
        {
          backtrace: ctx[:backtrace],
          tracers: ctx[:tracers],
        }
      else
        {}
      end
      # Since we're running one query, don't run a multiplex-level complexity analyzer
      all_results = multiplex([kwargs], max_complexity: nil, context: multiplex_context)
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

    # Search for a schema member using a string path
    # @example Finding a Field
    # Schema.find("Ensemble.musicians")
    #
    # @see {GraphQL::Schema::Finder} for more examples
    # @param path [String] A dot-separated path to the member
    # @raise [Schema::Finder::MemberNotFoundError] if path could not be found
    # @return [GraphQL::BaseType, GraphQL::Field, GraphQL::Argument, GraphQL::Directive] A GraphQL Schema Member
    def find(path)
      rebuild_artifacts unless defined?(@finder)
      @find_cache[path] ||= @finder.find(path)
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
        when GraphQL::BaseType, Class, Module
          parent_type.graphql_name
        when String
          parent_type
        else
          raise "Unexpected parent_type: #{parent_type}"
        end

        defined_field = @instrumented_field_map[parent_type_name][field_name]
        if defined_field
          defined_field
        elsif parent_type == query && (entry_point_field = introspection_system.entry_point(name: field_name))
          entry_point_field
        elsif (dynamic_field = introspection_system.dynamic_field(name: field_name))
          dynamic_field
        else
          nil
        end
      end
    end

    # Fields for this type, after instrumentation is applied
    # @return [Hash<String, GraphQL::Field>]
    def get_fields(type)
      @instrumented_field_map[type.graphql_name]
    end

    def type_from_ast(ast_node, context:)
      GraphQL::Schema::TypeExpression.build_type(self, ast_node)
    end

    # @see [GraphQL::Schema::Warden] Restricted access to members of a schema
    # @param type_defn [GraphQL::InterfaceType, GraphQL::UnionType] the type whose members you want to retrieve
    # @param context [GraphQL::Query::Context] The context for the current query
    # @return [Array<GraphQL::ObjectType>] types which belong to `type_defn` in this schema
    def possible_types(type_defn, context = GraphQL::Query::NullContext)
      if context == GraphQL::Query::NullContext
        @possible_types ||= GraphQL::Schema::PossibleTypes.new(self)
        @possible_types.possible_types(type_defn, context)
      else
        # Use the incoming context to cache this instance --
        # if it were cached on the schema, we'd have a memory leak
        # https://github.com/rmosolgo/graphql-ruby/issues/2878
        ns = context.namespace(:possible_types)
        per_query_possible_types = ns[:possible_types] ||= GraphQL::Schema::PossibleTypes.new(self)
        per_query_possible_types.possible_types(type_defn, context)
      end
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
      check_resolved_type(type, object, ctx) do |ok_type, ok_object, ok_ctx|
        if @resolve_type_proc.nil?
          raise(GraphQL::RequiredImplementationMissingError, "Can't determine GraphQL type for: #{ok_object.inspect}, define `resolve_type (type, obj, ctx) -> { ... }` inside `Schema.define`.")
        end
        @resolve_type_proc.call(ok_type, ok_object, ok_ctx)
      end
    end

    # This is a compatibility hack so that instance-level and class-level
    # methods can get correctness checks without calling one another
    # @api private
    def check_resolved_type(type, object, ctx = :__undefined__)
      if ctx == :__undefined__
        # Old method signature
        ctx = object
        object = type
        type = nil
      end

      if object.is_a?(GraphQL::Schema::Object)
        object = object.object
      end

      if type.respond_to?(:graphql_definition)
        type = type.graphql_definition
      end

      # Prefer a type-local function; fall back to the schema-level function
      type_proc = type && type.resolve_type_proc
      type_result = if type_proc
        type_proc.call(object, ctx)
      else
        yield(type, object, ctx)
      end

      if type_result.nil?
        nil
      else
        after_lazy(type_result) do |resolved_type_result|
          if resolved_type_result.respond_to?(:graphql_definition)
            resolved_type_result = resolved_type_result.graphql_definition
          end
          if !resolved_type_result.is_a?(GraphQL::BaseType)
            type_str = "#{resolved_type_result} (#{resolved_type_result.class.name})"
            raise "resolve_type(#{object}) returned #{type_str}, but it should return a GraphQL type"
          else
            resolved_type_result
          end
        end
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
        raise(GraphQL::RequiredImplementationMissingError, "Can't fetch an object for id \"#{id}\" because the schema's `object_from_id (id, ctx) -> { ... }` function is not defined")
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

    # Can't delegate to `class`
    alias :_schema_class :class
    def_delegators :_schema_class, :unauthorized_object, :unauthorized_field, :inaccessible_fields
    def_delegators :_schema_class, :directive
    def_delegators :_schema_class, :error_handler


    # Given this schema member, find the class-based definition object
    # whose `method_name` should be treated as an application hook
    # @see {.visible?}
    # @see {.accessible?}
    def call_on_type_class(member, method_name, context, default:)
      member = if member.respond_to?(:type_class)
        member.type_class
      else
        member
      end

      if member.respond_to?(:relay_node_type) && (t = member.relay_node_type)
        member = t
      end

      if member.respond_to?(method_name)
        member.public_send(method_name, context)
      else
        default
      end
    end

    def visible?(member, context)
      call_on_type_class(member, :visible?, context, default: true)
    end

    def accessible?(member, context)
      call_on_type_class(member, :accessible?, context, default: true)
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
        raise(GraphQL::RequiredImplementationMissingError, "Can't generate an ID for #{object.inspect} of type #{type}, schema's `id_from_object` must be defined")
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
    # @param using [Hash] Plugins to attach to the created schema with `use(key, value)`
    # @return [Class] the schema described by `document`
    def self.from_definition(definition_or_path, default_resolve: nil, parser: GraphQL.default_parser, using: {})
      # If the file ends in `.graphql`, treat it like a filepath
      if definition_or_path.end_with?(".graphql")
        GraphQL::Schema::BuildFromDefinition.from_definition_path(
          definition_or_path,
          default_resolve: default_resolve,
          parser: parser,
          using: using,
        )
      else
        GraphQL::Schema::BuildFromDefinition.from_definition(
          definition_or_path,
          default_resolve: default_resolve,
          parser: parser,
          using: using,
        )
      end
    end

    # Error that is raised when [#Schema#from_definition] is passed an invalid schema definition string.
    class InvalidDocumentError < Error; end;

    # Return the GraphQL IDL for the schema
    # @param context [Hash]
    # @param only [<#call(member, ctx)>]
    # @param except [<#call(member, ctx)>]
    # @return [String]
    def to_definition(only: nil, except: nil, context: {})
      GraphQL::Schema::Printer.print_schema(self, only: only, except: except, context: context)
    end

    # Return the GraphQL::Language::Document IDL AST for the schema
    # @param context [Hash]
    # @param only [<#call(member, ctx)>]
    # @param except [<#call(member, ctx)>]
    # @return [GraphQL::Language::Document]
    def to_document(only: nil, except: nil, context: {})
      GraphQL::Language::DocumentFromSchemaDefinition.new(self, only: only, except: except, context: context).document
    end

    # Return the Hash response of {Introspection::INTROSPECTION_QUERY}.
    # @param context [Hash]
    # @param only [<#call(member, ctx)>]
    # @param except [<#call(member, ctx)>]
    # @return [Hash] GraphQL result
    def as_json(only: nil, except: nil, context: {})
      execute(Introspection.query(include_deprecated_args: true), only: only, except: except, context: context).to_h
    end

    # Returns the JSON response of {Introspection::INTROSPECTION_QUERY}.
    # @see {#as_json}
    # @return [String]
    def to_json(*args)
      JSON.pretty_generate(as_json(*args))
    end

    def new_connections?
      !!connections
    end

    attr_accessor :connections

    class << self
      extend Forwardable
      # For compatibility, these methods all:
      # - Cause the Schema instance to be created, if it hasn't been created yet
      # - Delegate to that instance
      # Eventually, the methods will be moved into this class, removing the need for the singleton.
      def_delegators :graphql_definition,
        # Execution
        :execution_strategy_for_operation,
        :validate,
        # Configuration
        :metadata, :redefine,
        :id_from_object_proc, :object_from_id_proc,
        :id_from_object=, :object_from_id=,
        :remove_handler

      # @return [GraphQL::Subscriptions]
      attr_accessor :subscriptions

      # Returns the JSON response of {Introspection::INTROSPECTION_QUERY}.
      # @see {#as_json}
      # @return [String]
      def to_json(**args)
        JSON.pretty_generate(as_json(**args))
      end

      # Return the Hash response of {Introspection::INTROSPECTION_QUERY}.
      # @param context [Hash]
      # @param only [<#call(member, ctx)>]
      # @param except [<#call(member, ctx)>]
      # @return [Hash] GraphQL result
      def as_json(only: nil, except: nil, context: {})
        execute(Introspection.query(include_deprecated_args: true), only: only, except: except, context: context).to_h
      end

      # Return the GraphQL IDL for the schema
      # @param context [Hash]
      # @param only [<#call(member, ctx)>]
      # @param except [<#call(member, ctx)>]
      # @return [String]
      def to_definition(only: nil, except: nil, context: {})
        GraphQL::Schema::Printer.print_schema(self, only: only, except: except, context: context)
      end

      # Return the GraphQL::Language::Document IDL AST for the schema
      # @return [GraphQL::Language::Document]
      def to_document
        GraphQL::Language::DocumentFromSchemaDefinition.new(self).document
      end

      def find(path)
        if !@finder
          @find_cache = {}
          @finder ||= GraphQL::Schema::Finder.new(self)
        end
        @find_cache[path] ||= @finder.find(path)
      end

      def graphql_definition
        @graphql_definition ||= to_graphql
      end

      def default_filter
        GraphQL::Filter.new(except: default_mask)
      end

      def default_mask(new_mask = nil)
        if new_mask
          @own_default_mask = new_mask
        else
          @own_default_mask || find_inherited_value(:default_mask, Schema::NullMask)
        end
      end

      def static_validator
        GraphQL::StaticValidation::Validator.new(schema: self)
      end

      def use(plugin, **kwargs)
        if kwargs.any?
          plugin.use(self, **kwargs)
        else
          plugin.use(self)
        end
        own_plugins << [plugin, kwargs]
      end

      def plugins
        find_inherited_value(:plugins, EMPTY_ARRAY) + own_plugins
      end

      def to_graphql
        schema_defn = self.new
        schema_defn.raise_definition_error = true
        schema_defn.query = query && query.graphql_definition
        schema_defn.mutation = mutation && mutation.graphql_definition
        schema_defn.subscription = subscription && subscription.graphql_definition
        schema_defn.validate_timeout = validate_timeout
        schema_defn.max_complexity = max_complexity
        schema_defn.error_bubbling = error_bubbling
        schema_defn.max_depth = max_depth
        schema_defn.default_max_page_size = default_max_page_size
        schema_defn.orphan_types = orphan_types.map(&:graphql_definition)
        schema_defn.disable_introspection_entry_points = disable_introspection_entry_points?
        schema_defn.disable_schema_introspection_entry_point = disable_schema_introspection_entry_point?
        schema_defn.disable_type_introspection_entry_point = disable_type_introspection_entry_point?

        prepped_dirs = {}
        directives.each { |k, v| prepped_dirs[k] = v.graphql_definition}
        schema_defn.directives = prepped_dirs
        schema_defn.introspection_namespace = introspection
        schema_defn.resolve_type = method(:resolve_type)
        schema_defn.object_from_id = method(:object_from_id)
        schema_defn.id_from_object = method(:id_from_object)
        schema_defn.type_error = method(:type_error)
        schema_defn.context_class = context_class
        schema_defn.cursor_encoder = cursor_encoder
        schema_defn.tracers.concat(tracers)
        schema_defn.query_analyzers.concat(query_analyzers)
        schema_defn.analysis_engine = analysis_engine

        schema_defn.middleware.concat(all_middleware)
        schema_defn.multiplex_analyzers.concat(multiplex_analyzers)
        schema_defn.query_execution_strategy = query_execution_strategy
        schema_defn.mutation_execution_strategy = mutation_execution_strategy
        schema_defn.subscription_execution_strategy = subscription_execution_strategy
        schema_defn.default_mask = default_mask
        instrumenters.each do |step, insts|
          insts.each do |inst|
            schema_defn.instrumenters[step] << inst
          end
        end

        lazy_methods.each do |lazy_class, value_method|
          schema_defn.lazy_methods.set(lazy_class, value_method)
        end

        error_handler.each_rescue do |err_class, handler|
          schema_defn.rescue_from(err_class, &handler)
        end

        schema_defn.subscriptions ||= self.subscriptions

        if !schema_defn.interpreter?
          schema_defn.instrumenters[:query] << GraphQL::Schema::Member::Instrumentation
        end

        if new_connections?
          schema_defn.connections = self.connections
        end

        schema_defn.send(:rebuild_artifacts)

        schema_defn
      end

      # Build a map of `{ name => type }` and return it
      # @return [Hash<String => Class>] A dictionary of type classes by their GraphQL name
      # @see get_type Which is more efficient for finding _one type_ by name, because it doesn't merge hashes.
      def types
        non_introspection_types.merge(introspection_system.types)
      end

      # @param type_name [String]
      # @return [Module, nil] A type, or nil if there's no type called `type_name`
      def get_type(type_name)
        own_types[type_name] ||
          introspection_system.types[type_name] ||
          find_inherited_value(:types, EMPTY_HASH)[type_name]
      end

      # @api private
      attr_writer :connections

      # @return [GraphQL::Pagination::Connections] if installed
      def connections
        if defined?(@connections)
          @connections
        else
          inherited_connections = find_inherited_value(:connections, nil)
          # This schema is part of an inheritance chain which is using new connections,
          # make a new instance, so we don't pollute the upstream one.
          if inherited_connections
            @connections = Pagination::Connections.new(schema: self)
          else
            nil
          end
        end
      end

      def new_connections?
        !!connections
      end

      def query(new_query_object = nil)
        if new_query_object
          if @query_object
            raise GraphQL::Error, "Second definition of `query(...)` (#{new_query_object.inspect}) is invalid, already configured with #{@query_object.inspect}"
          else
            @query_object = new_query_object
            add_type_and_traverse(new_query_object, root: true)
            nil
          end
        else
          @query_object || find_inherited_value(:query)
        end
      end

      def mutation(new_mutation_object = nil)
        if new_mutation_object
          if @mutation_object
            raise GraphQL::Error, "Second definition of `mutation(...)` (#{new_mutation_object.inspect}) is invalid, already configured with #{@mutation_object.inspect}"
          else
            @mutation_object = new_mutation_object
            add_type_and_traverse(new_mutation_object, root: true)
            nil
          end
        else
          @mutation_object || find_inherited_value(:mutation)
        end
      end

      def subscription(new_subscription_object = nil)
        if new_subscription_object
          if @subscription_object
            raise GraphQL::Error, "Second definition of `subscription(...)` (#{new_subscription_object.inspect}) is invalid, already configured with #{@subscription_object.inspect}"
          else
            @subscription_object = new_subscription_object
            add_subscription_extension_if_necessary
            add_type_and_traverse(new_subscription_object, root: true)
            nil
          end
        else
          @subscription_object || find_inherited_value(:subscription)
        end
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

      def root_types
        @root_types
      end

      # @param type [Module] The type definition whose possible types you want to see
      # @return [Hash<String, Module>] All possible types, if no `type` is given.
      # @return [Array<Module>] Possible types for `type`, if it's given.
      def possible_types(type = nil, context = GraphQL::Query::NullContext)
        if type
          # TODO duck-typing `.possible_types` would probably be nicer here
          if type.kind.union?
            type.possible_types(context: context)
          else
            stored_possible_types = own_possible_types[type.graphql_name]
            visible_possible_types = if stored_possible_types && type.kind.interface?
              stored_possible_types.select do |possible_type|
                # Use `.graphql_name` comparison to match legacy vs class-based types.
                # When we don't need to support legacy `.define` types, use `.include?(type)` instead.
                possible_type.interfaces(context).any? { |interface| interface.graphql_name == type.graphql_name }
              end
            else
              stored_possible_types
            end
            visible_possible_types ||
              introspection_system.possible_types[type.graphql_name] ||
              (
                superclass.respond_to?(:possible_types) ?
                  superclass.possible_types(type, context) :
                  EMPTY_ARRAY
              )
          end
        else
          find_inherited_value(:possible_types, EMPTY_HASH)
            .merge(own_possible_types)
            .merge(introspection_system.possible_types)
        end
      end

      def union_memberships(type = nil)
        if type
          own_um = own_union_memberships.fetch(type.graphql_name, EMPTY_ARRAY)
          inherited_um = find_inherited_value(:union_memberships, EMPTY_HASH).fetch(type.graphql_name, EMPTY_ARRAY)
          own_um + inherited_um
        else
          joined_um = own_union_memberships.dup
          find_inherited_value(:union_memberhips, EMPTY_HASH).each do |k, v|
            um = joined_um[k] ||= []
            um.concat(v)
          end
          joined_um
        end
      end

      # @api private
      # @see GraphQL::Dataloader
      def dataloader_class
        @dataloader_class || GraphQL::Dataloader::NullDataloader
      end

      attr_writer :dataloader_class

      def references_to(to_type = nil, from: nil)
        @own_references_to ||= Hash.new { |h, k| h[k] = [] }
        if to_type
          if !to_type.is_a?(String)
            to_type = to_type.graphql_name
          end

          if from
            @own_references_to[to_type] << from
          else
            own_refs = @own_references_to[to_type]
            inherited_refs = find_inherited_value(:references_to, EMPTY_HASH)[to_type] || EMPTY_ARRAY
            own_refs + inherited_refs
          end
        else
          # `@own_references_to` can be quite large for big schemas,
          # and generally speaking, we won't inherit any values.
          # So optimize the most common case -- don't create a duplicate Hash.
          inherited_value = find_inherited_value(:references_to, EMPTY_HASH)
          if inherited_value.any?
            inherited_value.merge(@own_references_to)
          else
            @own_references_to
          end
        end
      end

      def type_from_ast(ast_node, context: nil)
        type_owner = context ? context.warden : self
        GraphQL::Schema::TypeExpression.build_type(type_owner, ast_node)
      end

      def get_field(type_or_name, field_name)
        parent_type = case type_or_name
        when LateBoundType
          get_type(type_or_name.name)
        when String
          get_type(type_or_name)
        when Module
          type_or_name
        else
          raise ArgumentError, "unexpected field owner for #{field_name.inspect}: #{type_or_name.inspect} (#{type_or_name.class})"
        end

        if parent_type.kind.fields? && (field = parent_type.get_field(field_name))
          field
        elsif parent_type == query && (entry_point_field = introspection_system.entry_point(name: field_name))
          entry_point_field
        elsif (dynamic_field = introspection_system.dynamic_field(name: field_name))
          dynamic_field
        else
          nil
        end
      end

      def get_fields(type)
        type.fields
      end

      def introspection(new_introspection_namespace = nil)
        if new_introspection_namespace
          @introspection = new_introspection_namespace
          # reset this cached value:
          @introspection_system = nil
        else
          @introspection || find_inherited_value(:introspection)
        end
      end

      def introspection_system
        if !@introspection_system
          @introspection_system = Schema::IntrospectionSystem.new(self)
          @introspection_system.resolve_late_bindings
        end
        @introspection_system
      end

      def cursor_encoder(new_encoder = nil)
        if new_encoder
          @cursor_encoder = new_encoder
        end
        @cursor_encoder || find_inherited_value(:cursor_encoder, Base64Encoder)
      end

      def default_max_page_size(new_default_max_page_size = nil)
        if new_default_max_page_size
          @default_max_page_size = new_default_max_page_size
        else
          @default_max_page_size || find_inherited_value(:default_max_page_size)
        end
      end

      def query_execution_strategy(new_query_execution_strategy = nil)
        if new_query_execution_strategy
          @query_execution_strategy = new_query_execution_strategy
        else
          @query_execution_strategy || find_inherited_value(:query_execution_strategy, self.default_execution_strategy)
        end
      end

      def mutation_execution_strategy(new_mutation_execution_strategy = nil)
        if new_mutation_execution_strategy
          @mutation_execution_strategy = new_mutation_execution_strategy
        else
          @mutation_execution_strategy || find_inherited_value(:mutation_execution_strategy, self.default_execution_strategy)
        end
      end

      def subscription_execution_strategy(new_subscription_execution_strategy = nil)
        if new_subscription_execution_strategy
          @subscription_execution_strategy = new_subscription_execution_strategy
        else
          @subscription_execution_strategy || find_inherited_value(:subscription_execution_strategy, self.default_execution_strategy)
        end
      end

      attr_writer :validate_timeout

      def validate_timeout(new_validate_timeout = nil)
        if new_validate_timeout
          @validate_timeout = new_validate_timeout
        elsif defined?(@validate_timeout)
          @validate_timeout
        else
          find_inherited_value(:validate_timeout)
        end
      end

      attr_writer :max_complexity

      def max_complexity(max_complexity = nil)
        if max_complexity
          @max_complexity = max_complexity
        elsif defined?(@max_complexity)
          @max_complexity
        else
          find_inherited_value(:max_complexity)
        end
      end

      attr_writer :analysis_engine

      def analysis_engine
        @analysis_engine || find_inherited_value(:analysis_engine, self.default_analysis_engine)
      end

      def using_ast_analysis?
        analysis_engine == GraphQL::Analysis::AST
      end

      def interpreter?
        query_execution_strategy == GraphQL::Execution::Interpreter &&
          mutation_execution_strategy == GraphQL::Execution::Interpreter &&
          subscription_execution_strategy == GraphQL::Execution::Interpreter
      end

      attr_writer :interpreter

      def error_bubbling(new_error_bubbling = nil)
        if !new_error_bubbling.nil?
          @error_bubbling = new_error_bubbling
        else
          @error_bubbling.nil? ? find_inherited_value(:error_bubbling) : @error_bubbling
        end
      end

      attr_writer :error_bubbling

      attr_writer :max_depth

      def max_depth(new_max_depth = nil)
        if new_max_depth
          @max_depth = new_max_depth
        elsif defined?(@max_depth)
          @max_depth
        else
          find_inherited_value(:max_depth)
        end
      end

      def disable_introspection_entry_points
        @disable_introspection_entry_points = true
        # TODO: this clears the cache made in `def types`. But this is not a great solution.
        @introspection_system = nil
      end

      def disable_schema_introspection_entry_point
        @disable_schema_introspection_entry_point = true
        # TODO: this clears the cache made in `def types`. But this is not a great solution.
        @introspection_system = nil
      end

      def disable_type_introspection_entry_point
        @disable_type_introspection_entry_point = true
        # TODO: this clears the cache made in `def types`. But this is not a great solution.
        @introspection_system = nil
      end

      def disable_introspection_entry_points?
        if instance_variable_defined?(:@disable_introspection_entry_points)
          @disable_introspection_entry_points
        else
          find_inherited_value(:disable_introspection_entry_points?, false)
        end
      end

      def disable_schema_introspection_entry_point?
        if instance_variable_defined?(:@disable_schema_introspection_entry_point)
          @disable_schema_introspection_entry_point
        else
          find_inherited_value(:disable_schema_introspection_entry_point?, false)
        end
      end

      def disable_type_introspection_entry_point?
        if instance_variable_defined?(:@disable_type_introspection_entry_point)
          @disable_type_introspection_entry_point
        else
          find_inherited_value(:disable_type_introspection_entry_point?, false)
        end
      end

      def orphan_types(*new_orphan_types)
        if new_orphan_types.any?
          new_orphan_types = new_orphan_types.flatten
          add_type_and_traverse(new_orphan_types, root: false)
          @orphan_types = new_orphan_types
          own_orphan_types.concat(new_orphan_types.flatten)
        end

        find_inherited_value(:orphan_types, EMPTY_ARRAY) + own_orphan_types
      end

      def default_execution_strategy
        if superclass <= GraphQL::Schema
          superclass.default_execution_strategy
        else
          @default_execution_strategy ||= GraphQL::Execution::Interpreter
        end
      end

      def default_analysis_engine
        if superclass <= GraphQL::Schema
          superclass.default_analysis_engine
        else
          @default_analysis_engine ||= GraphQL::Analysis::AST
        end
      end

      def context_class(new_context_class = nil)
        if new_context_class
          @context_class = new_context_class
        else
          @context_class || find_inherited_value(:context_class, GraphQL::Query::Context)
        end
      end

      def rescue_from(*err_classes, &handler_block)
        err_classes.each do |err_class|
          error_handler.rescue_from(err_class, handler_block)
        end
      end

      # rubocop:disable Lint/DuplicateMethods
      module ResolveTypeWithType
        def resolve_type(type, obj, ctx)
          first_resolved_type, resolved_value = if type.is_a?(Module) && type.respond_to?(:resolve_type)
            type.resolve_type(obj, ctx)
          else
            super
          end

          after_lazy(first_resolved_type) do |resolved_type|
            if resolved_type.nil? || (resolved_type.is_a?(Module) && resolved_type.respond_to?(:kind)) || resolved_type.is_a?(GraphQL::BaseType)
              if resolved_value
                [resolved_type, resolved_value]
              else
                resolved_type
              end
            else
              raise ".resolve_type should return a type definition, but got #{resolved_type.inspect} (#{resolved_type.class}) from `resolve_type(#{type}, #{obj}, #{ctx})`"
            end
          end
        end
      end

      def resolve_type(type, obj, ctx)
        if type.kind.object?
          type
        else
          raise GraphQL::RequiredImplementationMissingError, "#{self.name}.resolve_type(type, obj, ctx) must be implemented to use Union types or Interface types (tried to resolve: #{type.name})"
        end
      end
      # rubocop:enable Lint/DuplicateMethods

      def inherited(child_class)
        if self == GraphQL::Schema
          child_class.directives(default_directives.values)
        end
        child_class.singleton_class.prepend(ResolveTypeWithType)
        super
      end

      def object_from_id(node_id, ctx)
        raise GraphQL::RequiredImplementationMissingError, "#{self.name}.object_from_id(node_id, ctx) must be implemented to load by ID (tried to load from id `#{node_id}`)"
      end

      def id_from_object(object, type, ctx)
        raise GraphQL::RequiredImplementationMissingError, "#{self.name}.id_from_object(object, type, ctx) must be implemented to create global ids (tried to create an id for `#{object.inspect}`)"
      end

      def visible?(member, ctx)
        member.type_class.visible?(ctx)
      end

      def accessible?(member, ctx)
        member.type_class.accessible?(ctx)
      end

      # This hook is called when a client tries to access one or more
      # fields that fail the `accessible?` check.
      #
      # By default, an error is added to the response. Override this hook to
      # track metrics or return a different error to the client.
      #
      # @param error [InaccessibleFieldsError] The analysis error for this check
      # @return [AnalysisError, nil] Return an error to skip the query
      def inaccessible_fields(error)
        error
      end

      # This hook is called when an object fails an `authorized?` check.
      # You might report to your bug tracker here, so you can correct
      # the field resolvers not to return unauthorized objects.
      #
      # By default, this hook just replaces the unauthorized object with `nil`.
      #
      # Whatever value is returned from this method will be used instead of the
      # unauthorized object (accessible as `unauthorized_error.object`). If an
      # error is raised, then `nil` will be used.
      #
      # If you want to add an error to the `"errors"` key, raise a {GraphQL::ExecutionError}
      # in this hook.
      #
      # @param unauthorized_error [GraphQL::UnauthorizedError]
      # @return [Object] The returned object will be put in the GraphQL response
      def unauthorized_object(unauthorized_error)
        nil
      end

      # This hook is called when a field fails an `authorized?` check.
      #
      # By default, this hook implements the same behavior as unauthorized_object.
      #
      # Whatever value is returned from this method will be used instead of the
      # unauthorized field . If an error is raised, then `nil` will be used.
      #
      # If you want to add an error to the `"errors"` key, raise a {GraphQL::ExecutionError}
      # in this hook.
      #
      # @param unauthorized_error [GraphQL::UnauthorizedFieldError]
      # @return [Field] The returned field will be put in the GraphQL response
      def unauthorized_field(unauthorized_error)
        unauthorized_object(unauthorized_error)
      end

      def type_error(type_err, ctx)
        DefaultTypeError.call(type_err, ctx)
      end

      # A function to call when {#execute} receives an invalid query string
      #
      # The default is to add the error to `context.errors`
      # @param err [GraphQL::ParseError] The error encountered during parsing
      # @param ctx [GraphQL::Query::Context] The context for the query where the error occurred
      # @return void
      def parse_error(parse_err, ctx)
        ctx.errors.push(parse_err)
      end

      # @return [GraphQL::Execution::Errors]
      def error_handler
        @error_handler ||= GraphQL::Execution::Errors.new(self)
      end

      def lazy_resolve(lazy_class, value_method)
        lazy_methods.set(lazy_class, value_method)
      end

      def instrument(instrument_step, instrumenter, options = {})
        if instrument_step == :field
          GraphQL::Deprecation.warn "Field instrumentation (#{instrumenter.inspect}) will be removed in GraphQL-Ruby 2.0, please upgrade to field extensions: https://graphql-ruby.org/type_definitions/field_extensions.html"
        end

        step = if instrument_step == :field && options[:after_built_ins]
          :field_after_built_ins
        else
          instrument_step
        end

        own_instrumenters[step] << instrumenter
      end

      # Add several directives at once
      # @param new_directives [Class]
      def directives(*new_directives)
        if new_directives.any?
          new_directives.flatten.each { |d| directive(d) }
        end

        find_inherited_value(:directives, default_directives).merge(own_directives)
      end

      # Attach a single directive to this schema
      # @param new_directive [Class]
      # @return void
      def directive(new_directive)
        own_directives[new_directive.graphql_name] ||= begin
          add_type_and_traverse(new_directive, root: false)
          new_directive
        end
      end

      def default_directives
        @default_directives ||= {
          "include" => GraphQL::Schema::Directive::Include,
          "skip" => GraphQL::Schema::Directive::Skip,
          "deprecated" => GraphQL::Schema::Directive::Deprecated,
        }.freeze
      end

      def tracer(new_tracer)
        own_tracers << new_tracer
      end

      def tracers
        find_inherited_value(:tracers, EMPTY_ARRAY) + own_tracers
      end

      def query_analyzer(new_analyzer)
        if new_analyzer == GraphQL::Authorization::Analyzer
          GraphQL::Deprecation.warn("The Authorization query analyzer is deprecated. Authorizing at query runtime is generally a better idea.")
        end
        own_query_analyzers << new_analyzer
      end

      def query_analyzers
        find_inherited_value(:query_analyzers, EMPTY_ARRAY) + own_query_analyzers
      end

      def middleware(new_middleware = nil)
        if new_middleware
          GraphQL::Deprecation.warn "Middleware will be removed in GraphQL-Ruby 2.0, please upgrade to Field Extensions: https://graphql-ruby.org/type_definitions/field_extensions.html"
          own_middleware << new_middleware
        else
          # TODO make sure this is cached when running a query
          MiddlewareChain.new(steps: all_middleware, final_step: GraphQL::Execution::Execute::FieldResolveStep)
        end
      end

      def multiplex_analyzer(new_analyzer)
        own_multiplex_analyzers << new_analyzer
      end

      def multiplex_analyzers
        find_inherited_value(:multiplex_analyzers, EMPTY_ARRAY) + own_multiplex_analyzers
      end

      # Execute a query on itself.
      # @see {Query#initialize} for arguments.
      # @return [Hash] query result, ready to be serialized as JSON
      def execute(query_str = nil, **kwargs)
        if query_str
          kwargs[:query] = query_str
        end
        # Some of the query context _should_ be passed to the multiplex, too
        multiplex_context = if (ctx = kwargs[:context])
          {
            backtrace: ctx[:backtrace],
            tracers: ctx[:tracers],
          }
        else
          {}
        end
        # Since we're running one query, don't run a multiplex-level complexity analyzer
        all_results = multiplex([kwargs], max_complexity: nil, context: multiplex_context)
        all_results[0]
      end

      # Execute several queries on itself, concurrently.
      #
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
        schema = if interpreter?
          self
        else
          graphql_definition
        end
        GraphQL::Execution::Multiplex.run_all(schema, queries, **kwargs)
      end

      def instrumenters
        inherited_instrumenters = find_inherited_value(:instrumenters) || Hash.new { |h,k| h[k] = [] }
        inherited_instrumenters.merge(own_instrumenters) do |_step, inherited, own|
          inherited + own
        end
      end

      # @api private
      def add_subscription_extension_if_necessary
        if interpreter? && !defined?(@subscription_extension_added) && subscription && self.subscriptions
          @subscription_extension_added = true
          if subscription.singleton_class.ancestors.include?(Subscriptions::SubscriptionRoot)
            GraphQL::Deprecation.warn("`extend Subscriptions::SubscriptionRoot` is no longer required; you may remove it from #{self}'s `subscription` root type (#{subscription}).")
          else
            subscription.fields.each do |name, field|
              field.extension(Subscriptions::DefaultSubscriptionResolveExtension)
            end
          end
        end
      end

      def query_stack_error(query, err)
        query.context.errors.push(GraphQL::ExecutionError.new("This query is too large to execute."))
      end

      private

      def lazy_methods
        if !defined?(@lazy_methods)
          if inherited_map = find_inherited_value(:lazy_methods)
            # this isn't _completely_ inherited :S (Things added after `dup` won't work)
            @lazy_methods = inherited_map.dup
          else
            @lazy_methods = GraphQL::Execution::Lazy::LazyMethodMap.new
            @lazy_methods.set(GraphQL::Execution::Lazy, :value)
            @lazy_methods.set(GraphQL::Dataloader::Request, :load)
          end
        end
        @lazy_methods
      end

      def own_types
        @own_types ||= {}
      end

      def non_introspection_types
        find_inherited_value(:non_introspection_types, EMPTY_HASH).merge(own_types)
      end

      def own_plugins
        @own_plugins ||= []
      end

      def own_orphan_types
        @own_orphan_types ||= []
      end

      def own_possible_types
        @own_possible_types ||= {}
      end

      def own_union_memberships
        @own_union_memberships ||= {}
      end

      def own_directives
        @own_directives ||= {}
      end

      def own_instrumenters
        @own_instrumenters ||= Hash.new { |h,k| h[k] = [] }
      end

      def own_tracers
        @own_tracers ||= []
      end

      def own_query_analyzers
        @defined_query_analyzers ||= []
      end

      def all_middleware
        find_inherited_value(:all_middleware, EMPTY_ARRAY) + own_middleware
      end

      def own_middleware
        @own_middleware ||= []
      end

      def own_multiplex_analyzers
        @own_multiplex_analyzers ||= []
      end

      # @param t [Module, Array<Module>]
      # @return [void]
      def add_type_and_traverse(t, root:)
        if root
          @root_types ||= []
          @root_types << t
        end
        late_types = []
        new_types = Array(t)
        new_types.each { |t| add_type(t, owner: nil, late_types: late_types, path: [t.graphql_name]) }
        missed_late_types = 0
        while (late_type_vals = late_types.shift)
          type_owner, lt = late_type_vals
          if lt.is_a?(String)
            type = Member::BuildType.constantize(lt)
            # Reset the counter, since we might succeed next go-round
            missed_late_types = 0
            update_type_owner(type_owner, type)
            add_type(type, owner: type_owner, late_types: late_types, path: [type.graphql_name])
          elsif lt.is_a?(LateBoundType)
            if (type = get_type(lt.graphql_name))
              # Reset the counter, since we might succeed next go-round
              missed_late_types = 0
              update_type_owner(type_owner, type)
              add_type(type, owner: type_owner, late_types: late_types, path: [type.graphql_name])
            else
              missed_late_types += 1
              # Add it back to the list, maybe we'll be able to resolve it later.
              late_types << [type_owner, lt]
              if missed_late_types == late_types.size
                # We've looked at all of them and haven't resolved one.
                raise UnresolvedLateBoundTypeError.new(type: lt)
              else
                # Try the next one
              end
            end
          else
            raise ArgumentError, "Unexpected late type: #{lt.inspect}"
          end
        end
        nil
      end

      def update_type_owner(owner, type)
        case owner
        when Class
          if owner.kind.union?
            # It's a union with possible_types
            # Replace the item by class name
            owner.assign_type_membership_object_type(type)
            own_possible_types[owner.graphql_name] = owner.possible_types
          elsif type.kind.interface? && owner.kind.object?
            new_interfaces = []
            owner.interfaces.each do |int_t|
              if int_t.is_a?(String) && int_t == type.graphql_name
                new_interfaces << type
              elsif int_t.is_a?(LateBoundType) && int_t.graphql_name == type.graphql_name
                new_interfaces << type
              else
                # Don't re-add proper interface definitions,
                # they were probably already added, maybe with options.
              end
            end
            owner.implements(*new_interfaces)
            new_interfaces.each do |int|
              pt = own_possible_types[int.graphql_name] ||= []
              if !pt.include?(owner)
                pt << owner
              end
            end
          end

        when nil
          # It's a root type
          own_types[type.graphql_name] = type
        when GraphQL::Schema::Field, GraphQL::Schema::Argument
          orig_type = owner.type
          # Apply list/non-null wrapper as needed
          if orig_type.respond_to?(:of_type)
            transforms = []
            while (orig_type.respond_to?(:of_type))
              if orig_type.kind.non_null?
                transforms << :to_non_null_type
              elsif orig_type.kind.list?
                transforms << :to_list_type
              else
                raise "Invariant: :of_type isn't non-null or list"
              end
              orig_type = orig_type.of_type
            end
            transforms.reverse_each { |t| type = type.public_send(t) }
          end
          owner.type = type
        else
          raise "Unexpected update: #{owner.inspect} #{type.inspect}"
        end
      end

      def add_type(type, owner:, late_types:, path:)
        if type.respond_to?(:metadata) && type.metadata.is_a?(Hash)
          type_class = type.metadata[:type_class]
          if type_class.nil?
            raise ArgumentError, "Can't add legacy type: #{type} (#{type.class})"
          else
            type = type_class
          end
        elsif type.is_a?(String) || type.is_a?(GraphQL::Schema::LateBoundType)
          late_types << [owner, type]
          return
        end

        if owner.is_a?(Class) && owner < GraphQL::Schema::Union
          um = own_union_memberships[type.graphql_name] ||= []
          um << owner
        end

        if (prev_type = own_types[type.graphql_name])
          if prev_type != type
            raise DuplicateTypeNamesError.new(
              type_name: type.graphql_name,
              first_definition: prev_type,
              second_definition: type,
              path: path,
            )
          else
            # This type was already added
          end
        elsif type.is_a?(Class) && type < GraphQL::Schema::Directive
          type.arguments.each do |name, arg|
            arg_type = arg.type.unwrap
            references_to(arg_type, from: arg)
            add_type(arg_type, owner: arg, late_types: late_types, path: path + [name])
          end
        else
          own_types[type.graphql_name] = type
          add_directives_from(type)
          if type.kind.fields?
            type.fields.each do |name, field|
              field_type = field.type.unwrap
              references_to(field_type, from: field)
              field_path = path + [name]
              add_type(field_type, owner: field, late_types: late_types, path: field_path)
              add_directives_from(field)
              field.arguments.each do |arg_name, arg|
                add_directives_from(arg)
                arg_type = arg.type.unwrap
                references_to(arg_type, from: arg)
                add_type(arg_type, owner: arg, late_types: late_types, path: field_path + [arg_name])
              end
            end
          end
          if type.kind.input_object?
            type.arguments.each do |arg_name, arg|
              add_directives_from(arg)
              arg_type = arg.type.unwrap
              references_to(arg_type, from: arg)
              add_type(arg_type, owner: arg, late_types: late_types, path: path + [arg_name])
            end
          end
          if type.kind.union?
            own_possible_types[type.graphql_name] = type.possible_types
            type.possible_types.each do |t|
              add_type(t, owner: type, late_types: late_types, path: path + ["possible_types"])
            end
          end
          if type.kind.interface?
            type.orphan_types.each do |t|
              add_type(t, owner: type, late_types: late_types, path: path + ["orphan_types"])
            end
          end
          if type.kind.object?
            own_possible_types[type.graphql_name] = [type]
            type.interface_type_memberships.each do |interface_type_membership|
              case interface_type_membership
              when Schema::TypeMembership
                interface_type = interface_type_membership.abstract_type
                # We can get these now; we'll have to get late-bound types later
                if interface_type.is_a?(Module)
                  implementers = own_possible_types[interface_type.graphql_name] ||= []
                  implementers << type
                end
              when String, Schema::LateBoundType
                interface_type = interface_type_membership
              else
                raise ArgumentError, "Invariant: unexpected type membership for #{type.graphql_name}: #{interface_type_membership.class} (#{interface_type_membership.inspect})"
              end
              add_type(interface_type, owner: type, late_types: late_types, path: path + ["implements"])
            end
          end
        end
      end

      def add_directives_from(owner)
        owner.directives.each { |dir| directive(dir.class) }
      end
    end

    def dataloader_class
      self.class.dataloader_class
    end

    # Install these here so that subclasses will also install it.
    use(GraphQL::Pagination::Connections)

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

    def rebuild_artifacts
      if @rebuilding_artifacts
        raise CyclicalDefinitionError, "Part of the schema build process re-triggered the schema build process, causing an infinite loop. Avoid using Schema#types, Schema#possible_types, and Schema#get_field during schema build."
      else
        @rebuilding_artifacts = true
        @introspection_system = Schema::IntrospectionSystem.new(self)
        traversal = Traversal.new(self)
        @types = traversal.type_map
        @root_types = [query, mutation, subscription]
        @instrumented_field_map = traversal.instrumented_field_map
        @type_reference_map = traversal.type_reference_map
        @union_memberships = traversal.union_memberships
        @find_cache = {}
        @finder = Finder.new(self)
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
