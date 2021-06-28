# frozen_string_literal: true
require "graphql/field/resolve"

module GraphQL
  # @api deprecated
  class Field
    include GraphQL::Define::InstanceDefinable
    accepts_definitions :name, :description, :deprecation_reason,
      :resolve, :lazy_resolve,
      :type, :arguments,
      :property, :hash_key, :complexity,
      :mutation, :function,
      :edge_class,
      :relay_node_field,
      :relay_nodes_field,
      :subscription_scope,
      :trace,
      :introspection,
      argument: GraphQL::Define::AssignArgument

    ensure_defined(
      :name, :deprecation_reason, :description, :description=, :property, :hash_key,
      :mutation, :arguments, :complexity, :function,
      :resolve, :resolve=, :lazy_resolve, :lazy_resolve=, :lazy_resolve_proc, :resolve_proc,
      :type, :type=, :name=, :property=, :hash_key=,
      :relay_node_field, :relay_nodes_field, :edges?, :edge_class, :subscription_scope,
      :introspection?
    )

    # @return [Boolean] True if this is the Relay find-by-id field
    attr_accessor :relay_node_field

    # @return [Boolean] True if this is the Relay find-by-ids field
    attr_accessor :relay_nodes_field

    # @return [<#call(obj, args, ctx)>] A proc-like object which can be called to return the field's value
    attr_reader :resolve_proc

    # @return [<#call(obj, args, ctx)>] A proc-like object which can be called trigger a lazy resolution
    attr_reader :lazy_resolve_proc

    # @return [String] The name of this field on its {GraphQL::ObjectType} (or {GraphQL::InterfaceType})
    attr_reader :name
    alias :graphql_name :name

    # @return [String, nil] The client-facing description of this field
    attr_accessor :description

    # @return [String, nil] The client-facing reason why this field is deprecated (if present, the field is deprecated)
    attr_accessor :deprecation_reason

    # @return [Hash<String => GraphQL::Argument>] Map String argument names to their {GraphQL::Argument} implementations
    attr_accessor :arguments

    # @return [GraphQL::Relay::Mutation, nil] The mutation this field was derived from, if it was derived from a mutation
    attr_accessor :mutation

    # @return [Numeric, Proc] The complexity for this field (default: 1), as a constant or a proc like `->(query_ctx, args, child_complexity) { } # Numeric`
    attr_accessor :complexity

    # @return [Symbol, nil] The method to call on `obj` to return this field (overrides {#name} if present)
    attr_reader :property

    # @return [Object, nil] The key to access with `obj.[]` to resolve this field (overrides {#name} if present)
    attr_reader :hash_key

    # @return [Object, GraphQL::Function] The function used to derive this field
    attr_accessor :function

    attr_accessor :arguments_class

    attr_writer :connection
    attr_writer :introspection

    # @return [nil, String] Prefix for subscription names from this field
    attr_accessor :subscription_scope

    # @return [Boolean] True if this field should be traced. By default, fields are only traced if they are not a ScalarType or EnumType.
    attr_accessor :trace

    attr_accessor :ast_node

    # Future-compatible alias
    # @see {GraphQL::SchemaMember}
    alias :graphql_definition :itself

    # @return [Boolean]
    def connection?
      @connection
    end

    # @return [nil, Class]
    # @api private
    attr_accessor :edge_class

    # @return [Boolean]
    def edges?
      !!@edge_class
    end

    # @return [nil, Integer]
    attr_accessor :connection_max_page_size

    def initialize
      @complexity = 1
      @arguments = {}
      @resolve_proc = build_default_resolver
      @lazy_resolve_proc = DefaultLazyResolve
      @relay_node_field = false
      @connection = false
      @connection_max_page_size = nil
      @edge_class = nil
      @trace = nil
      @introspection = false
    end

    def initialize_copy(other)
      ensure_defined
      super
      @arguments = other.arguments.dup
    end

    # @return [Boolean] Is this field a predefined introspection field?
    def introspection?
      @introspection
    end

    # Get a value for this field
    # @example resolving a field value
    #   field.resolve(obj, args, ctx)
    #
    # @param object [Object] The object this field belongs to
    # @param arguments [Hash] Arguments declared in the query
    # @param context [GraphQL::Query::Context]
    def resolve(object, arguments, context)
      resolve_proc.call(object, arguments, context)
    end

    # Provide a new callable for this field's resolve function. If `nil`,
    # a new resolve proc will be build based on its {#name}, {#property} or {#hash_key}.
    # @param new_resolve_proc [<#call(obj, args, ctx)>, nil]
    def resolve=(new_resolve_proc)
      @resolve_proc = new_resolve_proc || build_default_resolver
    end

    def type=(new_return_type)
      @clean_type = nil
      @dirty_type = new_return_type
    end

    # Get the return type for this field.
    def type
      @clean_type ||= GraphQL::BaseType.resolve_related_type(@dirty_type)
    end

    def name=(new_name)
      old_name = defined?(@name) ? @name : nil
      @name = new_name

      if old_name != new_name && @resolve_proc.is_a?(Field::Resolve::NameResolve)
        # Since the NameResolve would use the old field name,
        # reset resolve proc when the name has changed
        self.resolve = nil
      end
    end

    # @param new_property [Symbol] A method to call to resolve this field. Overrides the existing resolve proc.
    def property=(new_property)
      @property = new_property
      self.resolve = nil # reset resolve proc
    end

    # @param new_hash_key [Symbol] A key to access with `#[key]` to resolve this field. Overrides the existing resolve proc.
    def hash_key=(new_hash_key)
      @hash_key = new_hash_key
      self.resolve = nil # reset resolve proc
    end

    def to_s
      "<Field name:#{name || "not-named"} desc:#{description} resolve:#{resolve_proc}>"
    end

    # If {#resolve} returned an object which should be handled lazily,
    # this method will be called later to force the object to return its value.
    # @param obj [Object] The {#resolve}-provided object, registered with {Schema#lazy_resolve}
    # @param args [GraphQL::Query::Arguments] Arguments to this field
    # @param ctx [GraphQL::Query::Context] Context for this field
    # @return [Object] The result of calling the registered method on `obj`
    def lazy_resolve(obj, args, ctx)
      @lazy_resolve_proc.call(obj, args, ctx)
    end

    # Assign a new resolve proc to this field. Used for {#lazy_resolve}
    def lazy_resolve=(new_lazy_resolve_proc)
      @lazy_resolve_proc = new_lazy_resolve_proc
    end

    # Prepare a lazy value for this field. It may be `then`-ed and resolved later.
    # @return [GraphQL::Execution::Lazy] A lazy wrapper around `obj` and its registered method name
    def prepare_lazy(obj, args, ctx)
      GraphQL::Execution::Lazy.new {
        lazy_resolve(obj, args, ctx)
      }
    end

    def type_class
      metadata[:type_class]
    end

    def get_argument(argument_name)
      arguments[argument_name]
    end

    private

    def build_default_resolver
      GraphQL::Field::Resolve.create_proc(self)
    end

    module DefaultLazyResolve
      def self.call(obj, args, ctx)
        ctx.schema.sync_lazy(obj)
      end
    end
  end
end
