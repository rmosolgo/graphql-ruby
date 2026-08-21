# frozen_string_literal: true
require "logger"
require "graphql/schema/addition"
require "graphql/schema/always_visible"
require "graphql/schema/base_64_encoder"
require "graphql/schema/find_inherited_value"
require "graphql/schema/finder"
require "graphql/schema/introspection_system"
require "graphql/schema/late_bound_type"
require "graphql/schema/ractor_shareable"
require "graphql/schema/timeout"
require "graphql/schema/type_expression"
require "graphql/schema/unique_within_type"
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
require "graphql/schema/directive/one_of"
require "graphql/schema/directive/skip"
require "graphql/schema/directive/feature"
require "graphql/schema/directive/flagged"
require "graphql/schema/directive/transform"
require "graphql/schema/directive/specified_by"
require "graphql/schema/type_membership"

require "graphql/schema/resolver"
require "graphql/schema/mutation"
require "graphql/schema/has_single_input_argument"
require "graphql/schema/relay_classic_mutation"
require "graphql/schema/subscription"
require "graphql/schema/visibility"

module GraphQL
  # A GraphQL schema which may be queried with [GraphQL::Query](rdoc-ref:GraphQL::Query).
  #
  # The [Schema](rdoc-ref:Schema) contains:
  #
  #  - types for exposing your application
  #  - query analyzers for assessing incoming queries (including max depth & max complexity restrictions)
  #  - execution strategies for running incoming queries
  #
  # Schemas start with root types, [Schema.query](rdoc-ref:GraphQL::Schema::query), [Schema.mutation](rdoc-ref:GraphQL::Schema::mutation) and [Schema.subscription](rdoc-ref:GraphQL::Schema::subscription).
  # The schema will traverse the tree of fields & types, using those as starting points.
  # Any undiscoverable types may be provided with the `types` configuration.
  #
  # Schemas can restrict large incoming queries with `max_depth` and `max_complexity` configurations.
  # (These configurations can be overridden by specific calls to [Schema.execute](rdoc-ref:Schema.execute))
  #
  # **Schema configuration reference**
  #
  # - Root types are registered with `query`, `mutation`, and `subscription`; use `orphan_types` for interface-only object types.
  # - `object_from_id`, `id_from_object`, and `resolve_type` implement Relay object identification and abstract-type resolution.
  # - `type_error`, `rescue_from`, `parse_error`, and `query_stack_error` provide execution error hooks.
  # - `max_depth`, `max_complexity`, `validate_timeout`, `validate_max_errors`, and `max_query_string_tokens` limit incoming work.
  # - `extra_types`, `introspection`, `trace_with`, analyzers, `context_class`, `query_class`, `lazy_resolve`, and `use` configure execution.
  #
  # The [schema definition guide](/schema/definition) contains setup examples and
  # links each contract above to its API method. Keep method-specific behavior in
  # the comments for those methods so this page remains the source of truth.
  #
  # ## Root Types
  #
  # `query`, `mutation`, and `subscription` register the entry-point object types
  # for a schema. Each may receive a type class or a block for lazy loading:
  #
  # ```ruby
  # query Types::Query
  # mutation { Types::Mutation }
  # subscription { Types::Subscription }
  # ```
  #
  # Use [Schema.orphan_types](rdoc-ref:GraphQL::Schema.orphan_types) for object
  # types which implement an interface but aren't reachable from a field return
  # type. Use [Schema.extra_types](rdoc-ref:GraphQL::Schema.extra_types) when a
  # type should be printed and included in introspection without being connected
  # to the schema's type graph.
  #
  # ## Object Identification
  #
  # Relay-style `node(id:)` fields, arguments configured with `loads:`, and the
  # ObjectCache use [Schema.object_from_id](rdoc-ref:GraphQL::Schema.object_from_id)
  # to fetch an application object. Return `nil` when the object does not exist or
  # is not visible to the current operation. Implement
  # [Schema.id_from_object](rdoc-ref:GraphQL::Schema.id_from_object) to produce a
  # stable ID which can be passed back to `object_from_id`.
  #
  # [Schema.resolve_type](rdoc-ref:GraphQL::Schema.resolve_type) maps an
  # application object to its runtime GraphQL type when a field returns an
  # interface or union.
  #
  # ## Error Handling
  #
  # Override [Schema.type_error](rdoc-ref:GraphQL::Schema.type_error) to handle
  # mismatches between application values and the GraphQL type system. Register
  # application exception handlers with [Schema.rescue_from](rdoc-ref:GraphQL::Schema.rescue_from).
  # [Schema.parse_error](rdoc-ref:GraphQL::Schema.parse_error) handles invalid
  # query strings, and [Schema.query_stack_error](rdoc-ref:GraphQL::Schema.query_stack_error)
  # is called when execution encounters a `SystemStackError`.
  #
  # ## Default Limits
  #
  # [Schema.max_depth](rdoc-ref:GraphQL::Schema.max_depth) limits nested field
  # selections and [Schema.max_complexity](rdoc-ref:GraphQL::Schema.max_complexity)
  # limits the calculated cost of a query. [Schema.default_max_page_size](rdoc-ref:GraphQL::Schema.default_max_page_size)
  # limits connection fields. [Schema.validate_timeout](rdoc-ref:GraphQL::Schema.validate_timeout),
  # [Schema.validate_max_errors](rdoc-ref:GraphQL::Schema.validate_max_errors), and
  # [Schema.max_query_string_tokens](rdoc-ref:GraphQL::Schema.max_query_string_tokens)
  # bound validation and parsing work. These limits can be configured on a schema
  # and, where documented, overridden for an individual execution.
  #
  # ## Introspection
  #
  # [Schema.extra_types](rdoc-ref:GraphQL::Schema.extra_types) adds otherwise
  # unreachable types to printed SDL and introspection results. Pass a custom
  # namespace to [Schema.introspection](rdoc-ref:GraphQL::Schema.introspection) to
  # replace or extend the default introspection system.
  #
  # ## Authorization
  #
  # [Schema.unauthorized_object](rdoc-ref:GraphQL::Schema.unauthorized_object)
  # and [Schema.unauthorized_field](rdoc-ref:GraphQL::Schema.unauthorized_field)
  # run when an authorization hook returns `false`. Return a replacement value or
  # raise [GraphQL::ExecutionError](rdoc-ref:GraphQL::ExecutionError) to add a
  # client-facing error.
  #
  # ## Execution Configuration
  #
  # [Schema.trace_with](rdoc-ref:GraphQL::Schema.trace_with) installs tracing
  # modules. [Schema.query_analyzer](rdoc-ref:GraphQL::Schema.query_analyzer) and
  # [Schema.multiplex_analyzer](rdoc-ref:GraphQL::Schema.multiplex_analyzer)
  # register analysis hooks. [Schema.default_logger](rdoc-ref:GraphQL::Schema.default_logger)
  # configures runtime logging, while [Schema.context_class](rdoc-ref:GraphQL::Schema.context_class)
  # and [Schema.query_class](rdoc-ref:GraphQL::Schema.query_class) select the
  # classes used during execution. [Schema.lazy_resolve](rdoc-ref:GraphQL::Schema.lazy_resolve)
  # registers promise-like values, and [Schema.use](rdoc-ref:GraphQL::Schema.use)
  # installs schema plugins such as Dataloader and Visibility.
  #
  # **Examples**
  #
  # **Example: defining a schema**
  #
  # ```ruby
  # class MySchema < GraphQL::Schema
  #   query QueryType
  #   # If types are only connected by way of interfaces, they must be added here
  #   orphan_types ImageType, AudioType
  # end
  # ```
  #
  # The API-specific portions of `guides/schema/definition.md` were migrated
  # here; the guide remains a standalone setup tutorial.
  # migrated from guides/schema/definition.md
  class Schema
    extend GraphQL::Schema::Member::HasAstNode
    extend GraphQL::Schema::FindInheritedValue
    extend Autoload

    autoload :BUILT_IN_TYPES, "graphql/schema/built_in_types"

    class DuplicateNamesError < GraphQL::Error
      attr_reader :duplicated_name
      def initialize(duplicated_name:, duplicated_definition_1:, duplicated_definition_2:)
        @duplicated_name = duplicated_name
        super(
          "Found two visible definitions for `#{duplicated_name}`: #{duplicated_definition_1}, #{duplicated_definition_2}"
        )
      end
    end

    class UnresolvedLateBoundTypeError < GraphQL::Error
      attr_reader :type
      def initialize(type:)
        @type = type
        super("Late bound type was never found: #{type.inspect}")
      end
    end

    # Error that is raised when [#Schema#from_definition] is passed an invalid schema definition string.
    class InvalidDocumentError < Error; end;

    class << self
      # Create schema with the result of an introspection query.
      #
      # **Parameters**
      #
      # - `introspection_result` (`Hash`) — A response from [GraphQL::Introspection::INTROSPECTION_QUERY](rdoc-ref:GraphQL::Introspection::INTROSPECTION_QUERY)
      #
      # **Returns**
      #
      # - `Class<GraphQL::Schema>` — the schema described by `input`
      #
      # :call-seq:
      #   from_introspection(Hash introspection_result) -> Class[GraphQL::Schema]
      def from_introspection(introspection_result)
        GraphQL::Schema::Loader.load(introspection_result)
      end

      # Create schema from an IDL schema or file containing an IDL definition.
      #
      # **Parameters**
      #
      # - `definition_or_path` (`String`) — A schema definition string, or a path to a file containing the definition
      # - `default_resolve` (`<#call(type, field, obj, args, ctx)>`) — A callable for handling field resolution
      # - `parser` (`Object`) — An object for handling definition string parsing (must respond to `parse`)
      # - `using` (`Hash`) — Plugins to attach to the created schema with `use(key, value)`
      #
      # **Returns**
      #
      # - `Class` — the schema described by `document`
      #
      # :call-seq:
      #   from_definition(String definition_or_path, #call(type, field, obj, args, ctx) default_resolve:, Object parser:, Hash using:, base_types:) -> Class
      def from_definition(definition_or_path, default_resolve: nil, parser: GraphQL.default_parser, using: {}, base_types: {})
        # If the file ends in `.graphql` or `.graphqls`, treat it like a filepath
        if definition_or_path.end_with?(".graphql") || definition_or_path.end_with?(".graphqls")
          GraphQL::Schema::BuildFromDefinition.from_definition_path(
            self,
            definition_or_path,
            default_resolve: default_resolve,
            parser: parser,
            using: using,
            base_types: base_types,
          )
        else
          GraphQL::Schema::BuildFromDefinition.from_definition(
            self,
            definition_or_path,
            default_resolve: default_resolve,
            parser: parser,
            using: using,
            base_types: base_types,
          )
        end
      end

      def deprecated_graphql_definition
        graphql_definition(silence_deprecation_warning: true)
      end

      # **Returns**
      #
      # - `GraphQL::Subscriptions`
      #
      # :call-seq:
      #   subscriptions(inherited:) -> GraphQL::Subscriptions
      def subscriptions(inherited: true)
        defined?(@subscriptions) ? @subscriptions : (inherited ? find_inherited_value(:subscriptions, nil) : nil)
      end

      def subscriptions=(new_implementation)
        @subscriptions = new_implementation
      end

      # **Parameters**
      #
      # - `new_mode` (`Symbol`) — If configured, this will be used when `context: { trace_mode: ... }` isn't set.
      #
      # :call-seq:
      #   default_trace_mode(Symbol new_mode)
      def default_trace_mode(new_mode = NOT_CONFIGURED)
        if !NOT_CONFIGURED.equal?(new_mode)
          @default_trace_mode = new_mode
        elsif defined?(@default_trace_mode) &&
            !@default_trace_mode.nil? # This `nil?` check seems necessary because of
                                      # Ractors silently initializing @default_trace_mode somehow
          @default_trace_mode
        elsif superclass.respond_to?(:default_trace_mode)
          superclass.default_trace_mode
        else
          :default
        end
      end

      def trace_class(new_class = nil)
        if new_class
          # If any modules were already added for `:default`,
          # re-apply them here
          mods = trace_modules_for(:default)
          mods.each { |mod| new_class.include(mod) }
          new_class.include(DefaultTraceClass)
          trace_mode(:default, new_class)
        end
        trace_class_for(:default, build: true)
      end

      # **Returns**
      #
      # - `Class` — Return the trace class to use for this mode, looking one up on the superclass if this Schema doesn't have one defined.
      #
      # :call-seq:
      #   trace_class_for(mode, build:) -> Class
      def trace_class_for(mode, build: false)
        if (trace_class = own_trace_modes[mode])
          trace_class
        elsif superclass.respond_to?(:trace_class_for) && (trace_class = superclass.trace_class_for(mode, build: false))
          trace_class
        elsif build
          own_trace_modes[mode] = build_trace_mode(mode)
        else
          nil
        end
      end

      # Configure `trace_class` to be used whenever `context: { trace_mode: mode_name }` is requested.
      # `default_trace_mode` is used when no `trace_mode: ...` is requested.
      #
      # When a `trace_class` is added this way, it will _not_ receive other modules added with `trace_with(...)`
      # unless `trace_mode` is explicitly given. (This class will not receive any default trace modules.)
      #
      # Subclasses of the schema will use `trace_class` as a base class for this mode and those
      # subclass also will _not_ receive default tracing modules.
      #
      # **Parameters**
      #
      # - `mode_name` (`Symbol`)
      # - `trace_class` (`Class`) — subclass of GraphQL::Tracing::Trace
      #
      # **Returns**
      #
      # - `Object` — void
      #
      # :call-seq:
      #   trace_mode(Symbol mode_name, Class trace_class) -> Object
      def trace_mode(mode_name, trace_class)
        own_trace_modes[mode_name] = trace_class
        nil
      end

      def own_trace_modes
        @own_trace_modes ||= {}
      end

      def build_trace_mode(mode)
        case mode
        when :default
          # Use the superclass's default mode if it has one, or else start an inheritance chain at the built-in base class.
          base_class = (superclass.respond_to?(:trace_class_for) && superclass.trace_class_for(mode, build: true)) || GraphQL::Tracing::Trace
          const_set(:DefaultTrace, Class.new(base_class) do
            include DefaultTraceClass
          end)
        else
          # First, see if the superclass has a custom-defined class for this.
          # Then, if it doesn't, use this class's default trace
          base_class = (superclass.respond_to?(:trace_class_for) && superclass.trace_class_for(mode)) || trace_class_for(:default, build: true)
          # Prepare the default trace class if it hasn't been initialized yet
          base_class ||= (own_trace_modes[:default] = build_trace_mode(:default))
          mods = trace_modules_for(mode)
          if base_class < DefaultTraceClass
            mods = trace_modules_for(:default) + mods
          end
          # Copy the existing default options into this mode's options
          default_options = trace_options_for(:default)
          add_trace_options_for(mode, default_options)

          Class.new(base_class) do
            !mods.empty? && include(*mods)
          end
        end
      end

      def own_trace_modules
        @own_trace_modules ||= Hash.new { |h, k| h[k] = [] }
      end

      # **Returns**
      #
      # - `Array<Module>` — Modules added for tracing in `trace_mode`, including inherited ones
      #
      # :call-seq:
      #   trace_modules_for(trace_mode) -> Array[Module]
      def trace_modules_for(trace_mode)
        modules = own_trace_modules[trace_mode]
        if superclass.respond_to?(:trace_modules_for)
          modules += superclass.trace_modules_for(trace_mode)
        end
        modules
      end


      # Returns the JSON response of [Introspection::INTROSPECTION_QUERY](rdoc-ref:Introspection::INTROSPECTION_QUERY).
      # See [as_json](rdoc-ref:GraphQL::Schema::as_json) Return a Hash representation of the schema
      #
      # **Returns**
      #
      # - `String`
      #
      # :call-seq:
      #   to_json(**args) -> String
      def to_json(**args)
        JSON.pretty_generate(as_json(**args))
      end

      # Return the Hash response of [Introspection::INTROSPECTION_QUERY](rdoc-ref:Introspection::INTROSPECTION_QUERY).
      #
      # **Parameters**
      #
      # - `context` (`Hash`)
      # - `include_deprecated_args` (`Boolean`) — If true, deprecated arguments will be included in the JSON response
      # - `include_schema_description` (`Boolean`) — If true, the schema's description will be queried and included in the response
      # - `include_is_repeatable` (`Boolean`) — If true, `isRepeatable: true|false` will be included with the schema's directives
      # - `include_specified_by_url` (`Boolean`) — If true, scalar types' `specifiedByUrl:` will be included in the response
      # - `include_is_one_of` (`Boolean`) — If true, `isOneOf: true|false` will be included with input objects
      #
      # **Returns**
      #
      # - `Hash` — GraphQL result
      #
      # :call-seq:
      #   as_json(Hash context:, bool include_deprecated_args:, bool include_schema_description:, bool include_is_repeatable:, bool include_specified_by_url:, bool include_is_one_of:) -> Hash
      def as_json(context: {}, include_deprecated_args: true, include_schema_description: false, include_is_repeatable: false, include_specified_by_url: false, include_is_one_of: false)
        introspection_query = Introspection.query(
          include_deprecated_args: include_deprecated_args,
          include_schema_description: include_schema_description,
          include_is_repeatable: include_is_repeatable,
          include_is_one_of: include_is_one_of,
          include_specified_by_url: include_specified_by_url,
        )

        execute(introspection_query, context: context).to_h
      end

      # Return the GraphQL IDL for the schema
      #
      # **Parameters**
      #
      # - `context` (`Hash`)
      #
      # **Returns**
      #
      # - `String`
      #
      # :call-seq:
      #   to_definition(Hash context:) -> String
      def to_definition(context: {})
        GraphQL::Schema::Printer.print_schema(self, context: context)
      end

      # Return the GraphQL::Language::Document IDL AST for the schema
      #
      # **Returns**
      #
      # - `GraphQL::Language::Document`
      #
      # :call-seq:
      #   to_document() -> GraphQL::Language::Document
      def to_document
        GraphQL::Language::DocumentFromSchemaDefinition.new(self).document
      end

      # **Returns**
      #
      # - `String, nil`
      #
      # :call-seq:
      #   description(new_description) -> String | nil
      def description(new_description = nil)
        if new_description
          @description = new_description
        elsif defined?(@description)
          @description
        else
          find_inherited_value(:description, nil)
        end
      end

      def find(path)
        if !@finder
          @find_cache = {}
          @finder ||= GraphQL::Schema::Finder.new(self)
        end
        @find_cache[path] ||= @finder.find(path)
      end

      def static_validator
        GraphQL::StaticValidation::Validator.new(schema: self)
      end

      # Add `plugin` to this schema
      #
      # **Parameters**
      #
      # - `plugin` (`#use`) — A Schema plugin
      #
      # **Returns**
      #
      # - `Object` — void
      #
      # :call-seq:
      #   use(#use plugin, **kwargs) -> Object
      def use(plugin, **kwargs)
        if !kwargs.empty?
          plugin.use(self, **kwargs)
        else
          plugin.use(self)
        end
        own_plugins << [plugin, kwargs]
      end

      def plugins
        find_inherited_value(:plugins, EMPTY_ARRAY) + own_plugins
      end

      attr_writer :null_context

      def null_context
        @null_context || GraphQL::Query::NullContext.instance
      end

      # Build a map of `{ name => type }` and return it.
      # `get_type` is more efficient for finding _one type_ by name, because it doesn't merge hashes.
      #
      # **Returns**
      #
      # - `Hash<String => Class>` — A dictionary of type classes by their GraphQL name
      #
      # :call-seq:
      #   types(context) -> Hash[String, Class]
      def types(context = null_context)
        if use_visibility_profile?
          types = Visibility::Profile.from_context(context, self)
          return types.all_types_h
        end
        all_types = non_introspection_types.merge(introspection_system.types)
        visible_types = {}
        all_types.each do |k, v|
          visible_types[k] =if v.is_a?(Array)
            visible_t = nil
            v.each do |t|
              if t.visible?(context)
                if visible_t.nil?
                  visible_t = t
                else
                  raise DuplicateNamesError.new(
                    duplicated_name: k, duplicated_definition_1: visible_t.inspect, duplicated_definition_2: t.inspect
                  )
                end
              end
            end
            visible_t
          else
            v
          end
        end
        visible_types
      end

      # **Parameters**
      #
      # - `type_name` (`String`)
      # - `context` (`GraphQL::Query::Context`) — Used for filtering definitions at query-time
      # - `use_visibility_profile` — Private, for migration to [Schema::Visibility](rdoc-ref:Schema::Visibility)
      #
      # **Returns**
      #
      # - `Module, nil` — A type, or nil if there's no type called `type_name`
      #
      # :call-seq:
      #   get_type(String type_name, GraphQL::Query::Context context, use_visibility_profile) -> Module | nil
      def get_type(type_name, context = null_context, use_visibility_profile = use_visibility_profile?)
        if use_visibility_profile
          profile = Visibility::Profile.from_context(context, self)
          return profile.type(type_name)
        end
        local_entry = own_types[type_name]
        type_defn = case local_entry
        when nil
          nil
        when Array
          if context.respond_to?(:types) && context.types.is_a?(GraphQL::Schema::Visibility::Profile)
            local_entry
          else
            visible_t = nil
            warden = Warden.from_context(context)
            local_entry.each do |t|
              if warden.visible_type?(t, context)
                if visible_t.nil?
                  visible_t = t
                else
                  raise DuplicateNamesError.new(
                    duplicated_name: type_name, duplicated_definition_1: visible_t.inspect, duplicated_definition_2: t.inspect
                  )
                end
              end
            end
            visible_t
          end
        when Module
          local_entry
        else
          raise "Invariant: unexpected own_types[#{type_name.inspect}]: #{local_entry.inspect}"
        end

        type_defn ||
          introspection_system.types[type_name] || # todo context-specific introspection?
          (superclass.respond_to?(:get_type) ? superclass.get_type(type_name, context, use_visibility_profile) : nil)
      end

      # **Returns**
      #
      # - `Boolean` — Does this schema have _any_ definition for a type named `type_name`, regardless of visibility?
      #
      # :call-seq:
      #   has_defined_type?(type_name) -> bool
      def has_defined_type?(type_name)
        own_types.key?(type_name) || introspection_system.types.key?(type_name) || (superclass.respond_to?(:has_defined_type?) ? superclass.has_defined_type?(type_name) : false)
      end

      attr_writer :connections # :nodoc:

      # **Returns**
      #
      # - `GraphQL::Pagination::Connections` — if installed
      #
      # :call-seq:
      #   connections() -> GraphQL::Pagination::Connections
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

      # Get or set the root `query` object for this schema.
      #
      # **Examples**
      #
      # **Example: Using `Types::Query` as the entry-point**
      #
      # ```ruby
      # query { Types::Query }
      # ```
      #
      # **Parameters**
      #
      # - `new_query_object` (`Class<GraphQL::Schema::Object>`) — The root type to use for queries
      # - `lazy_load_block` — If a block is given, then it will be called when GraphQL-Ruby needs the root query type.
      #
      # **Returns**
      #
      # - `Class<GraphQL::Schema::Object>, nil` — The configured query root type, if there is one.
      #
      # :call-seq:
      #   query(Class[GraphQL::Schema::Object] new_query_object, &lazy_load_block) -> Class[GraphQL::Schema::Object] | nil
      def query(new_query_object = nil, &lazy_load_block)
        if new_query_object || block_given?
          if @query_object
            dup_defn = new_query_object || yield
            raise GraphQL::Error, "Second definition of `query(...)` (#{dup_defn.inspect}) is invalid, already configured with #{@query_object.inspect}"
          elsif use_visibility_profile?
            if block_given?
              if visibility.preload?
                @query_object = lazy_load_block.call
                self.visibility.query_configured(@query_object)
              else
                @query_object = lazy_load_block
              end
            else
              @query_object = new_query_object
              self.visibility.query_configured(@query_object)
            end
          else
            @query_object = new_query_object || lazy_load_block.call
            add_type_and_traverse(@query_object, root: true)
          end
          nil
        elsif @query_object.is_a?(Proc)
          @query_object = @query_object.call
          self.visibility&.query_configured(@query_object)
          @query_object
        else
          @query_object || find_inherited_value(:query)
        end
      end

      # Get or set the root `mutation` object for this schema.
      #
      # **Examples**
      #
      # **Example: Using `Types::Mutation` as the entry-point**
      #
      # ```ruby
      # mutation { Types::Mutation }
      # ```
      #
      # **Parameters**
      #
      # - `new_mutation_object` (`Class<GraphQL::Schema::Object>`) — The root type to use for mutations
      # - `lazy_load_block` — If a block is given, then it will be called when GraphQL-Ruby needs the root mutation type.
      #
      # **Returns**
      #
      # - `Class<GraphQL::Schema::Object>, nil` — The configured mutation root type, if there is one.
      #
      # :call-seq:
      #   mutation(Class[GraphQL::Schema::Object] new_mutation_object, &lazy_load_block) -> Class[GraphQL::Schema::Object] | nil
      def mutation(new_mutation_object = nil, &lazy_load_block)
        if new_mutation_object || block_given?
          if @mutation_object
            dup_defn = new_mutation_object || yield
            raise GraphQL::Error, "Second definition of `mutation(...)` (#{dup_defn.inspect}) is invalid, already configured with #{@mutation_object.inspect}"
          elsif use_visibility_profile?
            if block_given?
              if visibility.preload?
                @mutation_object = lazy_load_block.call
                self.visibility.mutation_configured(@mutation_object)
              else
                @mutation_object = lazy_load_block
              end
            else
              @mutation_object = new_mutation_object
              self.visibility.mutation_configured(@mutation_object)
            end
          else
            @mutation_object = new_mutation_object || lazy_load_block.call
            add_type_and_traverse(@mutation_object, root: true)
          end
          nil
        elsif @mutation_object.is_a?(Proc)
          @mutation_object = @mutation_object.call
          self.visibility&.mutation_configured(@mutation_object)
          @mutation_object
        else
          @mutation_object || find_inherited_value(:mutation)
        end
      end

      # Get or set the root `subscription` object for this schema.
      #
      # **Examples**
      #
      # **Example: Using `Types::Subscription` as the entry-point**
      #
      # ```ruby
      # subscription { Types::Subscription }
      # ```
      #
      # **Parameters**
      #
      # - `new_subscription_object` (`Class<GraphQL::Schema::Object>`) — The root type to use for subscriptions
      # - `lazy_load_block` — If a block is given, then it will be called when GraphQL-Ruby needs the root subscription type.
      #
      # **Returns**
      #
      # - `Class<GraphQL::Schema::Object>, nil` — The configured subscription root type, if there is one.
      #
      # :call-seq:
      #   subscription(Class[GraphQL::Schema::Object] new_subscription_object, &lazy_load_block) -> Class[GraphQL::Schema::Object] | nil
      def subscription(new_subscription_object = nil, &lazy_load_block)
        if new_subscription_object || block_given?
          if @subscription_object
            dup_defn = new_subscription_object || yield
            raise GraphQL::Error, "Second definition of `subscription(...)` (#{dup_defn.inspect}) is invalid, already configured with #{@subscription_object.inspect}"
          elsif use_visibility_profile?
            if block_given?
              if visibility.preload?
                @subscription_object = lazy_load_block.call
                visibility.subscription_configured(@subscription_object)
              else
                @subscription_object = lazy_load_block
              end
            else
              @subscription_object = new_subscription_object
              self.visibility.subscription_configured(@subscription_object)
            end
            add_subscription_extension_if_necessary
          else
            @subscription_object = new_subscription_object || lazy_load_block.call
            add_subscription_extension_if_necessary
            add_type_and_traverse(@subscription_object, root: true)
          end
          nil
        elsif @subscription_object.is_a?(Proc)
          @subscription_object = @subscription_object.call
          add_subscription_extension_if_necessary
          self.visibility.subscription_configured(@subscription_object)
          @subscription_object
        else
          @subscription_object || find_inherited_value(:subscription)
        end
      end

      def root_type_for_operation(operation) # :nodoc:
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

      # **Returns**
      #
      # - `Array<Class>` — The root types (query, mutation, subscription) defined for this schema
      #
      # :call-seq:
      #   root_types() -> Array[Class]
      def root_types
        if use_visibility_profile?
          [query, mutation, subscription].compact
        else
          @root_types
        end
      end

      def warden_class # :nodoc:
        if defined?(@warden_class)
          @warden_class
        elsif superclass.respond_to?(:warden_class)
          superclass.warden_class
        else
          GraphQL::Schema::Warden
        end
      end

      attr_writer :warden_class # :nodoc:

      def visibility_profile_class # :nodoc:
        if defined?(@visibility_profile_class)
          @visibility_profile_class
        elsif superclass.respond_to?(:visibility_profile_class)
          superclass.visibility_profile_class
        else
          GraphQL::Schema::Visibility::Profile
        end
      end

      attr_writer :visibility_profile_class, :use_visibility_profile # :nodoc:
      attr_accessor :visibility # :nodoc:
      def use_visibility_profile? # :nodoc:
        if defined?(@use_visibility_profile)
          @use_visibility_profile
        elsif superclass.respond_to?(:use_visibility_profile?)
          superclass.use_visibility_profile?
        else
          false
        end
      end

      # **Parameters**
      #
      # - `type` (`Module`) — The type definition whose possible types you want to see
      # - `context` (`GraphQL::Query::Context`) — used for filtering visible possible types at runtime
      # - `use_visibility_profile` — Private, for migration to [Schema::Visibility](rdoc-ref:Schema::Visibility)
      #
      # **Returns**
      #
      # - `Hash<String, Module>` — All possible types, if no `type` is given.
      # - `Array<Module>` — Possible types for `type`, if it's given.
      #
      # :call-seq:
      #   possible_types(Module type, GraphQL::Query::Context context, use_visibility_profile) -> Hash[String, Module] | Array[Module]
      def possible_types(type = nil, context = null_context, use_visibility_profile = use_visibility_profile?)
        if use_visibility_profile
          if type
            return Visibility::Profile.from_context(context, self).possible_types(type)
          else
            raise "Schema.possible_types is not implemented for `use_visibility_profile?`"
          end
        end
        if type
          # TODO duck-typing `.possible_types` would probably be nicer here
          if type.kind.union?
            type.possible_types(context: context)
          else
            stored_possible_types = own_possible_types[type]
            visible_possible_types = if stored_possible_types && type.kind.interface?
              stored_possible_types.select do |possible_type|
                possible_type.interfaces(context).include?(type)
              end
            else
              stored_possible_types
            end
            visible_possible_types ||
              introspection_system.possible_types[type] ||
              (
                superclass.respond_to?(:possible_types) ?
                  superclass.possible_types(type, context, use_visibility_profile) :
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
          joined_um = own_union_memberships.transform_values(&:dup)
          find_inherited_value(:union_memberships, EMPTY_HASH).each do |k, v|
            um = joined_um[k] ||= []
            um.concat(v)
          end
          joined_um
        end
      end

      # See [GraphQL::Dataloader](rdoc-ref:GraphQL::Dataloader) GraphQL::Dataloader
      def dataloader_class # :nodoc:
        @dataloader_class || GraphQL::Dataloader::NullDataloader
      end

      attr_writer :dataloader_class

      def references_to(to_type = nil, from: nil)
        if to_type
          if from
            refs = own_references_to[to_type] ||= []
            refs << from
          else
            get_references_to(to_type) || EMPTY_ARRAY
          end
        else
          # `@own_references_to` can be quite large for big schemas,
          # and generally speaking, we won't inherit any values.
          # So optimize the most common case -- don't create a duplicate Hash.
          inherited_value = find_inherited_value(:references_to, EMPTY_HASH)
          if !inherited_value.empty?
            inherited_value.merge(own_references_to)
          else
            own_references_to
          end
        end
      end

      def type_from_ast(ast_node, context: self.query_class.new(self, "{ __typename }").context)
        GraphQL::Schema::TypeExpression.build_type(context.query.types, ast_node)
      end

      def get_field(type_or_name, field_name, context = null_context, use_visibility_profile = use_visibility_profile?)
        if use_visibility_profile
          profile = Visibility::Profile.from_context(context, self)
          parent_type = case type_or_name
          when String
            profile.type(type_or_name)
          when Module
            type_or_name
          when LateBoundType
            profile.type(type_or_name.name)
          else
            raise GraphQL::InvariantError, "Unexpected field owner for #{field_name.inspect}: #{type_or_name.inspect} (#{type_or_name.class})"
          end
          return profile.field(parent_type, field_name)
        end
        parent_type = case type_or_name
        when LateBoundType
          get_type(type_or_name.name, context)
        when String
          get_type(type_or_name, context)
        when Module
          type_or_name
        else
          raise GraphQL::InvariantError, "Unexpected field owner for #{field_name.inspect}: #{type_or_name.inspect} (#{type_or_name.class})"
        end

        if parent_type.kind.fields? && (field = parent_type.get_field(field_name, context))
          field
        elsif parent_type == query && (entry_point_field = introspection_system.entry_point(name: field_name))
          entry_point_field
        elsif (dynamic_field = introspection_system.dynamic_field(name: field_name))
          dynamic_field
        else
          nil
        end
      end

      def get_fields(type, context = null_context)
        type.fields(context)
      end

      # Pass a custom introspection module here to use it for this schema.
      #
      # **Parameters**
      #
      # - `new_introspection_namespace` (`Module`) — If given, use this module for custom introspection on the schema
      #
      # **Returns**
      #
      # - `Module, nil` — The configured namespace, if there is one
      #
      # :call-seq:
      #   introspection(Module new_introspection_namespace) -> Module | nil
      def introspection(new_introspection_namespace = nil)
        if new_introspection_namespace
          @introspection = new_introspection_namespace
          # reset this cached value:
          @introspection_system = nil
          introspection_system
          self.visibility&.introspection_system_configured(introspection_system)
          @introspection
        else
          @introspection || find_inherited_value(:introspection)
        end
      end

      # **Returns**
      #
      # - `Schema::IntrospectionSystem` — Based on [introspection](rdoc-ref:introspection)
      #
      # :call-seq:
      #   introspection_system() -> Schema::IntrospectionSystem
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

      # A limit on the number of tokens to accept on incoming query strings.
      # Use this to prevent parsing maliciously-large query strings.
      #
      # **Returns**
      #
      # - `nil, Integer`
      #
      # :call-seq:
      #   max_query_string_tokens(new_max_tokens) -> nil | Integer
      def max_query_string_tokens(new_max_tokens = NOT_CONFIGURED)
        if NOT_CONFIGURED.equal?(new_max_tokens)
          defined?(@max_query_string_tokens) ? @max_query_string_tokens : find_inherited_value(:max_query_string_tokens)
        else
          @max_query_string_tokens = new_max_tokens
        end
      end

      def default_page_size(new_default_page_size = nil)
        if new_default_page_size
          @default_page_size = new_default_page_size
        else
          @default_page_size || find_inherited_value(:default_page_size)
        end
      end

      def query_execution_strategy(new_query_execution_strategy = nil, deprecation_warning: true)
        if deprecation_warning
          warn "GraphQL::Schema.query_execution_strategy is deprecated without replacement. Use `GraphQL::Query.new` directly to create and execute a custom query instead."
          warn "  #{caller(1, 1).first}"
        end
        if new_query_execution_strategy
          @query_execution_strategy = new_query_execution_strategy
        else
          @query_execution_strategy || (superclass.respond_to?(:query_execution_strategy) ? superclass.query_execution_strategy(deprecation_warning: false) : self.default_execution_strategy)
        end
      end

      def mutation_execution_strategy(new_mutation_execution_strategy = nil, deprecation_warning: true)
        if deprecation_warning
          warn "GraphQL::Schema.mutation_execution_strategy is deprecated without replacement. Use `GraphQL::Query.new` directly to create and execute a custom query instead."
            warn "  #{caller(1, 1).first}"
        end
        if new_mutation_execution_strategy
          @mutation_execution_strategy = new_mutation_execution_strategy
        else
          @mutation_execution_strategy || (superclass.respond_to?(:mutation_execution_strategy) ? superclass.mutation_execution_strategy(deprecation_warning: false) : self.default_execution_strategy)
        end
      end

      def subscription_execution_strategy(new_subscription_execution_strategy = nil, deprecation_warning: true)
        if deprecation_warning
          warn "GraphQL::Schema.subscription_execution_strategy is deprecated without replacement. Use `GraphQL::Query.new` directly to create and execute a custom query instead."
          warn "  #{caller(1, 1).first}"
        end
        if new_subscription_execution_strategy
          @subscription_execution_strategy = new_subscription_execution_strategy
        else
          @subscription_execution_strategy || (superclass.respond_to?(:subscription_execution_strategy) ? superclass.subscription_execution_strategy(deprecation_warning: false) : self.default_execution_strategy)
        end
      end

      attr_writer :validate_timeout

      def validate_timeout(new_validate_timeout = NOT_CONFIGURED)
        if !NOT_CONFIGURED.equal?(new_validate_timeout)
          @validate_timeout = new_validate_timeout
        elsif defined?(@validate_timeout)
          @validate_timeout
        else
          find_inherited_value(:validate_timeout) || 3
        end
      end

      # Validate a query string according to this schema.
      #
      # **Parameters**
      #
      # - `string_or_document` (`String, GraphQL::Language::Nodes::Document`)
      #
      # **Returns**
      #
      # - `Array<GraphQL::StaticValidation::Error >`
      #
      # :call-seq:
      #   validate(String | GraphQL::Language::Nodes::Document string_or_document, rules:, context:) -> Array[GraphQL::StaticValidation::Error]
      def validate(string_or_document, rules: nil, context: nil)
        doc = if string_or_document.is_a?(String)
          GraphQL.parse(string_or_document, max_tokens: max_query_string_tokens)
        else
          string_or_document
        end
        query = query_class.new(self, document: doc, context: context)
        validator_opts = { schema: self }
        rules && (validator_opts[:rules] = rules)
        validator = GraphQL::StaticValidation::Validator.new(**validator_opts)
        res = validator.validate(query, timeout: validate_timeout, max_errors: validate_max_errors)
        res[:errors]
      end

      # **Parameters**
      #
      # - `new_query_class` (`Class<GraphQL::Query>`) — A subclass to use when executing queries
      #
      # :call-seq:
      #   query_class(Class[GraphQL::Query] new_query_class)
      def query_class(new_query_class = NOT_CONFIGURED)
        if NOT_CONFIGURED.equal?(new_query_class)
          @query_class || (superclass.respond_to?(:query_class) ? superclass.query_class : GraphQL::Query)
        else
          @query_class = new_query_class
        end
      end

      attr_writer :validate_max_errors

      def validate_max_errors(new_validate_max_errors = NOT_CONFIGURED)
        if NOT_CONFIGURED.equal?(new_validate_max_errors)
          defined?(@validate_max_errors) ? @validate_max_errors : find_inherited_value(:validate_max_errors)
        else
          @validate_max_errors = new_validate_max_errors
        end
      end

      attr_writer :max_complexity

      def max_complexity(max_complexity = nil, count_introspection_fields: true)
        if max_complexity
          @max_complexity = max_complexity
          @max_complexity_count_introspection_fields = count_introspection_fields
        elsif defined?(@max_complexity)
          @max_complexity
        else
          find_inherited_value(:max_complexity)
        end
      end

      def max_complexity_count_introspection_fields
        if defined?(@max_complexity_count_introspection_fields)
          @max_complexity_count_introspection_fields
        else
          find_inherited_value(:max_complexity_count_introspection_fields, true)
        end
      end

      attr_writer :analysis_engine

      def analysis_engine
        @analysis_engine || find_inherited_value(:analysis_engine, self.default_analysis_engine)
      end

      def error_bubbling(new_error_bubbling = nil)
        if !new_error_bubbling.nil?
          warn("error_bubbling(#{new_error_bubbling.inspect}) is deprecated; the default value of `false` will be the only option in GraphQL-Ruby 3.0")
          @error_bubbling = new_error_bubbling
        else
          @error_bubbling.nil? ? find_inherited_value(:error_bubbling) : @error_bubbling
        end
      end

      attr_writer :error_bubbling

      attr_writer :max_depth

      def max_depth(new_max_depth = nil, count_introspection_fields: true)
        if new_max_depth
          @max_depth = new_max_depth
          @count_introspection_fields = count_introspection_fields
        elsif defined?(@max_depth)
          @max_depth
        else
          find_inherited_value(:max_depth)
        end
      end

      def count_introspection_fields
        if defined?(@count_introspection_fields)
          @count_introspection_fields
        else
          find_inherited_value(:count_introspection_fields, true)
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

      # **Parameters**
      #
      # - `new_extra_types` (`Module`) — Type definitions to include in printing and introspection, even though they aren't referenced in the schema
      #
      # **Returns**
      #
      # - `Array<Module>` — Type definitions added to this schema
      #
      # :call-seq:
      #   extra_types(Module *new_extra_types) -> Array[Module]
      def extra_types(*new_extra_types)
        if !new_extra_types.empty?
          new_extra_types = new_extra_types.flatten
          @own_extra_types ||= []
          @own_extra_types.concat(new_extra_types)
        end
        inherited_et = find_inherited_value(:extra_types, nil)
        if inherited_et
          if @own_extra_types
            inherited_et + @own_extra_types
          else
            inherited_et
          end
        else
          @own_extra_types || EMPTY_ARRAY
        end
      end

      # Tell the schema about these types so that they can be registered as implementations of interfaces in the schema.
      #
      # This method must be used when an object type is connected to the schema as an interface implementor but
      # not as a return type of a field. In that case, if the object type isn't registered here, GraphQL-Ruby won't be able to find it.
      #
      # **Parameters**
      #
      # - `new_orphan_types` (`Array<Class<GraphQL::Schema::Object>>`) — Object types to register as implementations of interfaces in the schema.
      #
      # **Returns**
      #
      # - `Array<Class<GraphQL::Schema::Object>>` — All previously-registered orphan types for this schema
      #
      # :call-seq:
      #   orphan_types(Array[Class[GraphQL::Schema::Object]] *new_orphan_types) -> Array[Class[GraphQL::Schema::Object]]
      def orphan_types(*new_orphan_types)
        if !new_orphan_types.empty?
          new_orphan_types = new_orphan_types.flatten
          non_object_types = new_orphan_types.reject { |ot| ot.is_a?(Class) && ot < GraphQL::Schema::Object }
          if !non_object_types.empty?
            raise ArgumentError, <<~ERR
              Only object type classes should be added as `orphan_types(...)`.

              - Remove these no-op types from `orphan_types`: #{non_object_types.map { |t| "#{t.inspect} (#{t.kind.name})"}.join(", ")}
              - See https://graphql-ruby.org/type_definitions/interfaces.html#orphan-types

              To add other types to your schema, you might want `extra_types`: https://graphql-ruby.org/schema/definition.html#extra-types
            ERR
          end
          add_type_and_traverse(new_orphan_types, root: false) unless use_visibility_profile?
          own_orphan_types.concat(new_orphan_types.flatten)
          self.visibility&.orphan_types_configured(new_orphan_types)
        end

        inherited_ot = find_inherited_value(:orphan_types, nil)
        if inherited_ot
          if !own_orphan_types.empty?
            inherited_ot + own_orphan_types
          else
            inherited_ot
          end
        else
          own_orphan_types
        end
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


      # **Parameters**
      #
      # - `new_default_logger` (`#log`) — Something to use for logging messages
      #
      # :call-seq:
      #   default_logger(#log new_default_logger)
      def default_logger(new_default_logger = NOT_CONFIGURED)
        if NOT_CONFIGURED.equal?(new_default_logger)
          if defined?(@default_logger)
            @default_logger
          elsif superclass.respond_to?(:default_logger)
            superclass.default_logger
          elsif defined?(Rails) && Rails.respond_to?(:logger) && (rails_logger = Rails.logger)
            rails_logger
          else
            def_logger = Logger.new($stdout)
            def_logger.info! # It doesn't output debug info by default
            def_logger
          end
        elsif new_default_logger == nil
          @default_logger = Logger.new(IO::NULL)
        else
          @default_logger = new_default_logger
        end
      end

      # **Parameters**
      #
      # - `context` (`GraphQL::Query::Context, nil`)
      #
      # **Returns**
      #
      # - `Logger` — A logger to use for this context configuration, falling back to [.default_logger](rdoc-ref:.default_logger)
      #
      # :call-seq:
      #   logger_for(GraphQL::Query::Context | nil context) -> Logger
      def logger_for(context)
        if context && context[:logger] == false
          Logger.new(IO::NULL)
        elsif context && (l = context[:logger])
          l
        else
          default_logger
        end
      end

      # **Parameters**
      #
      # - `new_context_class` (`Class<GraphQL::Query::Context>`) — A subclass to use when executing queries
      #
      # :call-seq:
      #   context_class(Class[GraphQL::Query::Context] new_context_class)
      def context_class(new_context_class = nil)
        if new_context_class
          @context_class = new_context_class
        else
          @context_class || find_inherited_value(:context_class, GraphQL::Query::Context)
        end
      end

      # Register a handler for errors raised during execution. The handlers can return a new value or raise a new error.
      #
      # **Examples**
      #
      # **Example: Handling "not found" with a client-facing error**
      #
      # ```ruby
      # rescue_from(ActiveRecord::NotFound) { raise GraphQL::ExecutionError, "An object could not be found" }
      # ```
      #
      # **Parameters**
      #
      # - `err_classes` (`Array<StandardError>`) — Classes which should be rescued by `handler_block`
      # - `handler_block` — The code to run when one of those errors is raised during execution
      #
      # **Yields**
      #
      # - `error` (`StandardError`) — An instance of one of the configured `err_classes`
      # - `object` (`Object`) — The current application object in the query when the error was raised
      # - `arguments` (`GraphQL::Query::Arguments`) — The current field arguments when the error was raised
      # - `context` (`GraphQL::Query::Context`) — The context for the currently-running operation
      # - `Object` — Some object to use in the place where this error was raised
      #
      # **Raises**
      #
      # - `GraphQL::ExecutionError` — In the handler, raise to add a client-facing error to the response
      # - `StandardError` — In the handler, raise to crash the query with a developer-facing error
      #
      # :call-seq:
      #   rescue_from(Array[StandardError] *err_classes, &handler_block)
      def rescue_from(*err_classes, &handler_block)
        err_classes.each do |err_class|
          Execution::Errors.register_rescue_from(err_class, error_handlers[:subclass_handlers], handler_block)
        end
      end

      def error_handlers
        @error_handlers ||= begin
          new_handler_hash = ->(h, k) {
            h[k] = {
              class: k,
              handler: nil,
              subclass_handlers: Hash.new(&new_handler_hash),
            }
          }
          {
            class: nil,
            handler: nil,
            subclass_handlers: Hash.new(&new_handler_hash),
          }
        end
      end

      attr_accessor :using_backtrace # :nodoc:

      def handle_or_reraise(context, err, object: context[:current_object], arguments: context[:current_arguments], field: context[:current_field]) # :nodoc:
        handler = Execution::Errors.find_handler_for(self, err.class)
        if handler
          arguments = arguments.respond_to?(:keyword_arguments) ? arguments.keyword_arguments : arguments
          if object.is_a?(GraphQL::Schema::Object)
            object = object.object
          end
          handler[:handler].call(err, object, arguments, context, field)
        else
          if (context[:backtrace] || using_backtrace) && !err.is_a?(GraphQL::ExecutionError)
            err = GraphQL::Backtrace::TracedError.new(err, context)
          end

          raise err
        end
      end

      # rubocop:disable Lint/DuplicateMethods
      module ResolveTypeWithType
        def resolve_type(type, obj, ctx)
          maybe_lazy_resolve_type_result = if type.is_a?(Module) && type.respond_to?(:resolve_type)
            type.resolve_type(obj, ctx)
          else
            super
          end

          after_lazy(maybe_lazy_resolve_type_result) do |resolve_type_result|
            if resolve_type_result.is_a?(Array) && resolve_type_result.size == 2
              resolved_type = resolve_type_result[0]
              resolved_value = resolve_type_result[1]
            else
              resolved_type = resolve_type_result
              resolved_value = obj
            end

            if resolved_type.nil? || (resolved_type.is_a?(Module) && resolved_type.respond_to?(:kind))
              [resolved_type, resolved_value]
            else
              raise ".resolve_type should return a type definition, but got #{resolved_type.inspect} (#{resolved_type.class}) from `resolve_type(#{type}, #{obj}, #{ctx})`"
            end
          end
        end
      end

      # GraphQL-Ruby calls this method during execution when it needs the application to determine the type to use for an object.
      #
      # Usually, this object was returned from a field whose return type is an [GraphQL::Schema::Interface](rdoc-ref:GraphQL::Schema::Interface) or a [GraphQL::Schema::Union](rdoc-ref:GraphQL::Schema::Union).
      # But this method is called in other cases, too -- for example, when [GraphQL::Schema::Argument#loads](rdoc-ref:GraphQL::Schema::Argument#loads) cases an object to be directly loaded from the database.
      #
      # **Examples**
      #
      # **Example: Returning a GraphQL type based on the object's class name**
      #
      # ```ruby
      # class MySchema < GraphQL::Schema
      #   def resolve_type(_abs_type, object, _context)
      #     graphql_type_name = "Types::#{object.class.name}Type"
      #     graphql_type_name.constantize # If this raises a NameError, then come implement special cases in this method
      #   end
      # end
      # ```
      #
      # **Parameters**
      #
      # - `abstract_type` (`Class, Module, nil`) — The Interface or Union type which is being resolved, if there is one
      # - `application_object` (`Object`) — The object returned from a field whose type must be determined
      # - `context` (`GraphQL::Query::Context`) — The query context for the currently-executing query
      #
      # **Returns**
      #
      # - `Class<GraphQL::Schema::Object>` — The Object type definition to use for `obj`
      #
      # :call-seq:
      #   resolve_type(Class | Module | nil abstract_type, Object application_object, GraphQL::Query::Context context) -> Class[GraphQL::Schema::Object]
      def resolve_type(abstract_type, application_object, context)
        raise GraphQL::RequiredImplementationMissingError, "#{self.name}.resolve_type(abstract_type, application_object, context) must be implemented to use Union types, Interface types, `loads:`, or `run_partials` (tried to resolve: #{abstract_type.name})"
      end
      # rubocop:enable Lint/DuplicateMethods

      def inherited(child_class)
        if self == GraphQL::Schema
          child_class.directives(default_directives.values)
          child_class.extend(SubclassGetReferencesTo)
        end
        # Make sure the child class has these built out, so that
        # subclasses can be modified by later calls to `trace_with`
        own_trace_modes.each do |name, _class|
          child_class.own_trace_modes[name] = child_class.build_trace_mode(name)
        end
        child_class.singleton_class.prepend(ResolveTypeWithType)

        if use_visibility_profile?
          vis = self.visibility
          child_class.visibility = vis.dup_for(child_class)
        end
        child_class.null_context = Query::NullContext.new(schema: child_class)
        super
      end

      # Fetch an object based on an incoming ID and the current context. This method should return an object
      # from your application, or return `nil` if there is no object or the object shouldn't be available to this operation.
      #
      # See [id_from_object](rdoc-ref:id_from_object) which produces these IDs
      #
      # **Examples**
      #
      # **Example: Fetching an object with Rails's GlobalID**
      #
      # ```ruby
      # def self.object_from_id(object_id, _context)
      #   GlobalID.find(global_id)
      #   # TODO: use `context[:current_user]` to determine if this object is authorized.
      # end
      # ```
      #
      # **Parameters**
      #
      # - `object_id` (`String`) — The ID to fetch an object for. This may be client-provided (as in `node(id: ...)` or `loads:`) or previously stored by the schema (eg, by the `ObjectCache`)
      # - `context` (`GraphQL::Query::Context`) — The context for the currently-executing operation
      #
      # **Returns**
      #
      # - `Object, nil` — The application which `object_id` references, or `nil` if there is no object or the current operation shouldn't have access to the object
      #
      # :call-seq:
      #   object_from_id(String object_id, GraphQL::Query::Context context) -> Object | nil
      def object_from_id(object_id, context)
        raise GraphQL::RequiredImplementationMissingError, "#{self.name}.object_from_id(object_id, context) must be implemented to load by ID (tried to load from id `#{object_id}`)"
      end

      # Return a stable ID string for `object` so that it can be refetched later, using [.object_from_id](rdoc-ref:.object_from_id).
      #
      # [GlobalID](https://github.com/rails/globalid) and [SQIDs](https://sqids.org/ruby) can both be used to create IDs.
      #
      # **Examples**
      #
      # **Example: Using Rails's GlobalID to generate IDs**
      #
      # ```ruby
      # def self.id_from_object(application_object, graphql_type, context)
      #   application_object.to_gid_param
      # end
      # ```
      #
      # **Parameters**
      #
      # - `application_object` (`Object`) — Some object encountered by GraphQL-Ruby while running a query
      # - `graphql_type` (`Class, Module`) — The type that GraphQL-Ruby is using for `application_object` during this query
      # - `context` (`GraphQL::Query::Context`) — The context for the operation that is currently running
      #
      # **Returns**
      #
      # - `String` — A stable identifier which can be passed to [.object_from_id](rdoc-ref:.object_from_id) later to re-fetch `application_object`
      #
      # :call-seq:
      #   id_from_object(Object application_object, Class | Module graphql_type, GraphQL::Query::Context context) -> String
      def id_from_object(application_object, graphql_type, context)
        raise GraphQL::RequiredImplementationMissingError, "#{self.name}.id_from_object(application_object, graphql_type, context) must be implemented to create global ids (tried to create an id for `#{application_object.inspect}`)"
      end

      def visible?(member, ctx)
        member.visible?(ctx)
      end

      def schema_directive(dir_class, **options)
        @own_schema_directives ||= []
        Member::HasDirectives.add_directive(self, @own_schema_directives, dir_class, options)
      end

      def schema_directives
        Member::HasDirectives.get_directives(self, @own_schema_directives, :schema_directives)
      end

      # Called when a type is needed by name at runtime
      def load_type(type_name, ctx)
        get_type(type_name, ctx)
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
      # If you want to add an error to the `"errors"` key, raise a [GraphQL::ExecutionError](rdoc-ref:GraphQL::ExecutionError)
      # in this hook.
      #
      # **Parameters**
      #
      # - `unauthorized_error` (`GraphQL::UnauthorizedError`)
      #
      # **Returns**
      #
      # - `Object` — The returned object will be put in the GraphQL response
      #
      # :call-seq:
      #   unauthorized_object(GraphQL::UnauthorizedError unauthorized_error) -> Object
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
      # If you want to add an error to the `"errors"` key, raise a [GraphQL::ExecutionError](rdoc-ref:GraphQL::ExecutionError)
      # in this hook.
      #
      # **Parameters**
      #
      # - `unauthorized_error` (`GraphQL::UnauthorizedFieldError`)
      #
      # **Returns**
      #
      # - `Field` — The returned field will be put in the GraphQL response
      #
      # :call-seq:
      #   unauthorized_field(GraphQL::UnauthorizedFieldError unauthorized_error) -> Field
      def unauthorized_field(unauthorized_error)
        unauthorized_object(unauthorized_error)
      end

      # Called at runtime when GraphQL-Ruby encounters a mismatch between the application behavior
      # and the GraphQL type system.
      #
      # The default implementation of this method is to follow the GraphQL specification,
      # but you can override this to report errors to your bug tracker or customize error handling.
      #
      # **Parameters**
      #
      # - `type_error` (`GraphQL::Error`) — several specific error classes are passed here, see the default implementation for details
      # - `context` (`GraphQL::Query::Context`) — the context for the currently-running operation
      #
      # **Returns**
      #
      # - `void`
      #
      # **Raises**
      #
      # - `GraphQL::ExecutionError` — to return this error to the client
      # - `GraphQL::Error` — to crash the query and raise a developer-facing error
      #
      # :call-seq:
      #   type_error(GraphQL::Error type_error, GraphQL::Query::Context context) -> void | GraphQL::ExecutionError | GraphQL::Error
      def type_error(type_error, context)
        case type_error
        when GraphQL::InvalidNullError
          execution_error = GraphQL::ExecutionError.new(type_error.message, ast_nodes: type_error.ast_nodes)
          execution_error.path = type_error.path || context[:current_path]

          context.errors << execution_error
          execution_error
        when GraphQL::UnresolvedTypeError, GraphQL::StringEncodingError, GraphQL::IntegerEncodingError
          raise type_error
        when GraphQL::IntegerDecodingError
          nil
        end
      end

      # A function to call when [.execute](rdoc-ref:.execute) receives an invalid query string
      #
      # The default is to add the error to `context.errors`
      #
      # **Parameters**
      #
      # - `parse_err` (`GraphQL::ParseError`) — The error encountered during parsing
      # - `ctx` (`GraphQL::Query::Context`) — The context for the query where the error occurred
      #
      # **Returns**
      #
      # - `Object` — void
      #
      # :call-seq:
      #   parse_error(GraphQL::ParseError parse_err, GraphQL::Query::Context ctx) -> Object
      def parse_error(parse_err, ctx)
        ctx.errors.push(parse_err)
      end

      def lazy_resolve(lazy_class, value_method)
        lazy_methods.set(lazy_class, value_method)
      end

      def resolves_lazies?
        lazy_method_count = 0
        lazy_methods.each do |k, v|
          if !v.nil?
            lazy_method_count += 1
          end
        end
        lazy_method_count > 2
      end

      def instrument(instrument_step, instrumenter, options = {})
        warn <<~WARN
        Schema.instrument is deprecated, use `trace_with` instead: https://graphql-ruby.org/queries/tracing.html"
          (From `#{self}.instrument(#{instrument_step}, #{instrumenter})` at #{caller(1, 1).first})

        WARN
        trace_with(Tracing::LegacyHooksTrace)
        own_instrumenters[instrument_step] << instrumenter
      end

      # Add several directives at once
      #
      # **Parameters**
      #
      # - `new_directives` (`Class`)
      #
      # :call-seq:
      #   directives(Class *new_directives)
      def directives(*new_directives)
        if !new_directives.empty?
          new_directives.flatten.each { |d| directive(d) }
        end

        inherited_dirs = find_inherited_value(:directives, default_directives)
        if !own_directives.empty?
          inherited_dirs.merge(own_directives)
        else
          inherited_dirs
        end
      end

      # Attach a single directive to this schema
      #
      # **Parameters**
      #
      # - `new_directive` (`Class`)
      #
      # **Returns**
      #
      # - `Object` — void
      #
      # :call-seq:
      #   directive(Class new_directive) -> Object
      def directive(new_directive)
        if use_visibility_profile?
          own_directives[new_directive.graphql_name] = new_directive
        else
          add_type_and_traverse(new_directive, root: false)
        end
      end

      def default_directives
        @default_directives ||= {
          "include" => GraphQL::Schema::Directive::Include,
          "skip" => GraphQL::Schema::Directive::Skip,
          "deprecated" => GraphQL::Schema::Directive::Deprecated,
          "oneOf" => GraphQL::Schema::Directive::OneOf,
          "specifiedBy" => GraphQL::Schema::Directive::SpecifiedBy,
        }.freeze
      end

      # **Returns**
      #
      # - `GraphQL::Tracing::DetailedTrace` — if it has been configured for this schema
      #
      # :call-seq:
      #   detailed_trace -> GraphQL::Tracing::DetailedTrace
      attr_accessor :detailed_trace

      # See [Tracing::DetailedTrace](rdoc-ref:Tracing::DetailedTrace) DetailedTrace saves traces when this method returns true
      #
      # **Parameters**
      #
      # - `query` (`GraphQL::Query, GraphQL::Execution::Multiplex`) — Called with a multiplex when multiple queries are executed at once (with [.multiplex](rdoc-ref:.multiplex))
      #
      # **Returns**
      #
      # - `Boolean` — When `true`, save a detailed trace for this query.
      #
      # :call-seq:
      #   detailed_trace?(GraphQL::Query | GraphQL::Execution::Multiplex query) -> bool
      def detailed_trace?(query)
        raise "#{self} must implement `def.detailed_trace?(query)` to use DetailedTrace. Implement this method in your schema definition."
      end

      def tracer(new_tracer, silence_deprecation_warning: false)
        if !silence_deprecation_warning
          warn("`Schema.tracer(#{new_tracer.inspect})` is deprecated; use module-based `trace_with` instead. See: https://graphql-ruby.org/queries/tracing.html")
          warn "  #{caller(1, 1).first}"
        end
        default_trace = trace_class_for(:default, build: true)
        if default_trace.nil? || !(default_trace < GraphQL::Tracing::CallLegacyTracers)
          trace_with(GraphQL::Tracing::CallLegacyTracers)
        end

        own_tracers << new_tracer
      end

      def tracers
        inherited = find_inherited_value(:tracers, EMPTY_ARRAY)
        if inherited.length > 0
          if own_tracers.length > 0
            inherited + own_tracers
          else
            inherited
          end
        else
          own_tracers
        end
      end

      # Mix `trace_mod` into this schema's `Trace` class so that its methods will be called at runtime.
      #
      # You can attach a module to run in only _some_ circumstances by using `mode:`. When a module is added with `mode:`,
      # it will only run for queries with a matching `context[:trace_mode]`.
      #
      # Any custom trace modes _also_ include the default `trace_with ...` modules (that is, those added _without_ any particular `mode: ...` configuration).
      #
      # See [GraphQL::Tracing::Trace](rdoc-ref:GraphQL::Tracing::Trace) Tracing::Trace for available tracing methods
      #
      # **Examples**
      #
      # **Example: Adding a trace in a special mode**
      #
      # ```ruby
      # # only runs when `query.context[:trace_mode]` is `:special`
      # trace_with SpecialTrace, mode: :special
      # ```
      #
      # **Parameters**
      #
      # - `trace_mod` (`Module`) — A module that implements tracing methods
      # - `mode` (`Symbol`) — Trace module will only be used for this trade mode
      # - `options` (`Hash`) — Keywords that will be passed to the tracing class during `#initialize`
      #
      # **Returns**
      #
      # - `void`
      #
      # :call-seq:
      #   trace_with(Module trace_mod, Symbol mode:, Hash **options) -> void
      def trace_with(trace_mod, mode: :default, **options)
        if mode.is_a?(Array)
          mode.each { |m| trace_with(trace_mod, mode: m, **options) }
        else
          tc = own_trace_modes[mode] ||= build_trace_mode(mode)
          tc.include(trace_mod)
          own_trace_modules[mode] << trace_mod
          add_trace_options_for(mode, options)
          if mode == :default
            # This module is being added as a default tracer. If any other mode classes
            # have already been created, but get their default behavior from a superclass,
            # Then mix this into this schema's subclass.
            # (But don't mix it into mode classes that aren't default-based.)
            own_trace_modes.each do |other_mode_name, other_mode_class|
              if other_mode_class < DefaultTraceClass
                # Don't add it back to the inheritance tree if it's already there
                if !(other_mode_class < trace_mod)
                  other_mode_class.include(trace_mod)
                end
                # Add any options so they'll be available
                add_trace_options_for(other_mode_name, options)
              end
            end
          end
        end
        nil
      end

      # The options hash for this trace mode
      #
      # **Returns**
      #
      # - `Hash`
      #
      # :call-seq:
      #   trace_options_for(mode) -> Hash
      def trace_options_for(mode)
        @trace_options_for_mode ||= {}
        @trace_options_for_mode[mode] ||= begin
          # It may be time to create an options hash for a mode that wasn't registered yet.
          # Mix in the default options in that case.
          default_options = mode == :default ? EMPTY_HASH : trace_options_for(:default)
          # Make sure this returns a new object so that other hashes aren't modified later
          if superclass.respond_to?(:trace_options_for)
            superclass.trace_options_for(mode).merge(default_options)
          else
            default_options.dup
          end
        end
      end

      # Create a trace instance which will include the trace modules specified for the optional mode.
      #
      # If no `mode:` is given, then [default_trace_mode](rdoc-ref:default_trace_mode) will be used.
      #
      # If this schema is using [Tracing::DetailedTrace](rdoc-ref:Tracing::DetailedTrace) and [.detailed_trace?](rdoc-ref:.detailed_trace?) returns `true`, then
      # DetailedTrace's mode will override the passed-in `mode`.
      #
      # **Parameters**
      #
      # - `mode` (`Symbol`) — Trace modules for this trade mode will be included
      # - `options` (`Hash`) — Keywords that will be passed to the tracing class during `#initialize`
      #
      # **Returns**
      #
      # - `Tracing::Trace`
      #
      # :call-seq:
      #   new_trace(Symbol mode:, Hash **options) -> Tracing::Trace
      def new_trace(mode: nil, **options)
        should_sample = if detailed_trace
          if (query = options[:query])
            detailed_trace?(query)
          elsif (multiplex = options[:multiplex])
            if multiplex.queries.length == 1
              detailed_trace?(multiplex.queries.first)
            else
              detailed_trace?(multiplex)
            end
          end
        else
          false
        end

        if should_sample
          mode = detailed_trace.trace_mode
        else
          target = options[:query] || options[:multiplex]
          mode ||= target && target.context[:trace_mode]
        end

        trace_mode = mode || default_trace_mode
        base_trace_options = trace_options_for(trace_mode)
        trace_options = base_trace_options.merge(options)
        trace_class_for_mode = trace_class_for(trace_mode, build: true)
        trace_class_for_mode.new(**trace_options)
      end

      # See [GraphQL::Analysis](rdoc-ref:GraphQL::Analysis) the analysis system
      #
      # **Parameters**
      #
      # - `new_analyzer` (`Class<GraphQL::Analysis::Analyzer>`) — An analyzer to run on queries to this schema
      #
      # :call-seq:
      #   query_analyzer(Class[GraphQL::Analysis::Analyzer] new_analyzer)
      def query_analyzer(new_analyzer)
        own_query_analyzers << new_analyzer
      end

      def query_analyzers
        inherited_qa = find_inherited_value(:query_analyzers, EMPTY_ARRAY)
        inherited_qa.empty? ? own_query_analyzers : (inherited_qa + own_query_analyzers)
      end

      # See [GraphQL::Analysis](rdoc-ref:GraphQL::Analysis) the analysis system
      #
      # **Parameters**
      #
      # - `new_analyzer` (`Class<GraphQL::Analysis::Analyzer>`) — An analyzer to run on multiplexes to this schema
      #
      # :call-seq:
      #   multiplex_analyzer(Class[GraphQL::Analysis::Analyzer] new_analyzer)
      def multiplex_analyzer(new_analyzer)
        own_multiplex_analyzers << new_analyzer
      end

      def multiplex_analyzers
        find_inherited_value(:multiplex_analyzers, EMPTY_ARRAY) + own_multiplex_analyzers
      end

      def sanitized_printer(new_sanitized_printer = nil)
        if new_sanitized_printer
          @own_sanitized_printer = new_sanitized_printer
        else
          @own_sanitized_printer || GraphQL::Language::SanitizedPrinter
        end
      end

      # Execute a query on itself.
      # See the [GraphQL::Query](rdoc-ref:GraphQL::Query) constructor for arguments.
      #
      # `query_str` may be a query string; alternatively pass `document:` with a
      # parsed document. The common options are `variables:`, `context:`,
      # `root_value:`, `operation_name:`, `validate:`, `max_depth:`, and
      # `max_complexity:`. The returned result can be serialized directly as JSON.
      #
      # **Returns**
      #
      # - `GraphQL::Query::Result` — query result, ready to be serialized as JSON
      #
      # :call-seq:
      #   execute(query_str, **kwargs) -> GraphQL::Query::Result
      def execute(query_str = nil, **kwargs)
        if default_execution_next
          execute_next(query_str, **kwargs)
        else
          execute_legacy(query_str, **kwargs)
        end
      end

      def execute_legacy(query_str = nil, **kwargs)
        if query_str
          kwargs[:query] = query_str
        end
        # Some of the query context _should_ be passed to the multiplex, too
        multiplex_context = if (ctx = kwargs[:context])
          {
            backtrace: ctx[:backtrace],
            tracers: ctx[:tracers],
            trace: ctx[:trace],
            dataloader: ctx[:dataloader],
            trace_mode: ctx[:trace_mode],
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
      # See the [GraphQL::Query](rdoc-ref:GraphQL::Query) constructor for query keyword arguments.
      # Multiplex-level execution is handled by the interpreter's
      # `GraphQL::Execution::Interpreter.run_all` method.
      #
      # **Examples**
      #
      # **Example: Run several queries at once**
      #
      # ```ruby
      # context = { ... }
      # queries = [
      #   { query: params[:query_1], variables: params[:variables_1], context: context },
      #   { query: params[:query_2], variables: params[:variables_2], context: context },
      # ]
      # results = MySchema.multiplex(queries)
      # render json: {
      #   result_1: results[0],
      #   result_2: results[1],
      # }
      # ```
      #
      # **Parameters**
      #
      # - `queries` (`Array<Hash>`) — Keyword arguments for each query
      #
      # **Options**
      #
      # - `kwargs.:context` (`Hash`) — ({}) Multiplex-level context
      # - `kwargs.:max_complexity` (`nil, Integer`) — (nil)
      #
      # **Returns**
      #
      # - `Array<GraphQL::Query::Result>` — One result for each query in the input
      #
      # :call-seq:
      #   multiplex(Array[Hash] queries, **kwargs) -> Array[GraphQL::Query::Result]
      def multiplex(queries, **kwargs)
        if @default_execution_next
          multiplex_next(queries, **kwargs)
        else
          GraphQL::Execution::Interpreter.run_all(self, queries, **kwargs)
        end
      end

      def default_execution_next(new_value = NOT_CONFIGURED)
        if !NOT_CONFIGURED.equal?(new_value)
          @default_execution_next = new_value
        elsif instance_variable_defined?(:@default_execution_next)
          @default_execution_next
        elsif superclass.respond_to?(:default_execution_next)
          superclass.default_execution_next
        else
          false
        end
      end

      def instrumenters
        inherited_instrumenters = find_inherited_value(:instrumenters) || Hash.new { |h,k| h[k] = [] }
        inherited_instrumenters.merge(own_instrumenters) do |_step, inherited, own|
          inherited + own
        end
      end

      def add_subscription_extension_if_necessary # :nodoc:
        # TODO: when there's a proper API for extending root types, migrat this to use it.
        if !defined?(@subscription_extension_added) && @subscription_object.is_a?(Class) && self.subscriptions
          @subscription_extension_added = true
          subscription.all_field_definitions.each do |field|
            if !field.extensions.any? { |ext| ext.is_a?(Subscriptions::DefaultSubscriptionResolveExtension) }
              field.extension(Subscriptions::DefaultSubscriptionResolveExtension)
            end
          end
        end
      end

      # Called when execution encounters a `SystemStackError`. By default, it adds a client-facing error to the response.
      # You could modify this method to report this error to your bug tracker.
      #
      # **Parameters**
      #
      # - `query` (`GraphQL::Query`)
      # - `err` (`SystemStackError`)
      #
      # **Returns**
      #
      # - `void`
      #
      # :call-seq:
      #   query_stack_error(GraphQL::Query query, SystemStackError err) -> void
      def query_stack_error(query, err)
        query.context.errors.push(GraphQL::ExecutionError.new("This query is too large to execute."))
      end

      # Call the given block at the right time, either:
      # - Right away, if `value` is not registered with `lazy_resolve`
      # - After resolving `value`, if it's registered with `lazy_resolve` (eg, `Promise`)
      def after_lazy(value, &block) # :nodoc:
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
      #
      # **Parameters**
      #
      # - `value` (`Object`) — an instance of a class registered with [.lazy_resolve](rdoc-ref:.lazy_resolve)
      #
      # **Returns**
      #
      # - `Object` — A GraphQL-ready (non-lazy) object
      def sync_lazy(value) # :nodoc:
        lazy_method = lazy_method_name(value)
        if lazy_method
          synced_value = value.public_send(lazy_method)
          sync_lazy(synced_value)
        else
          value
        end
      end

      # **Returns**
      #
      # - `Symbol, nil` — The method name to lazily resolve `obj`, or nil if `obj`'s class wasn't registered with [.lazy_resolve](rdoc-ref:.lazy_resolve).
      #
      # :call-seq:
      #   lazy_method_name(obj) -> Symbol | nil
      def lazy_method_name(obj)
        lazy_methods.get(obj)
      end

      # **Returns**
      #
      # - `Boolean` — True if this object should be lazily resolved
      #
      # :call-seq:
      #   lazy?(obj) -> bool
      def lazy?(obj)
        !!lazy_method_name(obj)
      end

      # Return a lazy if any of `maybe_lazies` are lazy,
      # otherwise, call the block eagerly and return the result.
      #
      # **Parameters**
      #
      # - `maybe_lazies` (`Array`)
      def after_any_lazies(maybe_lazies) # :nodoc:
        if maybe_lazies.any? { |l| lazy?(l) }
          GraphQL::Execution::Lazy.all(maybe_lazies).then do |result|
            yield result
          end
        else
          yield maybe_lazies
        end
      end

      # Returns `DidYouMean` if it's defined.
      # Override this to return `nil` if you don't want to use `DidYouMean`
      def did_you_mean(new_dym = NOT_CONFIGURED)
        if NOT_CONFIGURED.equal?(new_dym)
          if defined?(@did_you_mean)
            @did_you_mean
          else
            find_inherited_value(:did_you_mean, defined?(DidYouMean) ? DidYouMean : nil)
          end
        else
          @did_you_mean = new_dym
        end
      end


      # This setting controls how GraphQL-Ruby handles empty selections on Union types.
      #
      # To opt into future, spec-compliant behavior where these selections are rejected, set this to `false`.
      #
      # If you need to support previous, non-spec behavior which allowed selecting union fields
      # but *not* selecting any fields on that union, set this to `true` to continue allowing that behavior.
      #
      # If this is `true`, then [.legacy_invalid_empty_selections_on_union_with_type](rdoc-ref:.legacy_invalid_empty_selections_on_union_with_type) will be called with [Query](rdoc-ref:Query) objects
      # with that kind of selections. You must implement that method
      #
      # **Parameters**
      #
      # - `new_value` (`Boolean`)
      #
      # **Returns**
      #
      # - `true, false, nil`
      #
      # :call-seq:
      #   allow_legacy_invalid_empty_selections_on_union(bool new_value) -> true | false | nil
      def allow_legacy_invalid_empty_selections_on_union(new_value = NOT_CONFIGURED)
        if NOT_CONFIGURED.equal?(new_value)
          if defined?(@allow_legacy_invalid_empty_selections_on_union)
            @allow_legacy_invalid_empty_selections_on_union
          else
            find_inherited_value(:allow_legacy_invalid_empty_selections_on_union)
          end
        else
          @allow_legacy_invalid_empty_selections_on_union = new_value
        end
      end

      # This method is called during validation when a previously-allowed, but non-spec
      # query is encountered where a union field has no child selections on it.
      #
      # If `legacy_invalid_empty_selections_on_union_with_type` is overridden, this method will not be called.
      #
      # You should implement this method or `legacy_invalid_empty_selections_on_union_with_type`
      # to log the violation so that you can contact clients and notify them about changing their queries.
      # Then return a suitable value to tell GraphQL-Ruby how to continue.
      #
      # **Parameters**
      #
      # - `query` (`GraphQL::Query`)
      #
      # **Returns**
      #
      # - `:return_validation_error` — Let GraphQL-Ruby return the (new) normal validation error for this query
      # - `String` — A validation error to return for this query
      # - `nil` — Don't send the client an error, continue the legacy behavior (allow this query to execute)
      #
      # :call-seq:
      #   legacy_invalid_empty_selections_on_union(GraphQL::Query query) -> :return_validation_error | String | nil
      def legacy_invalid_empty_selections_on_union(query)
        raise "Implement `def self.legacy_invalid_empty_selections_on_union_with_type(query, type)` or `def self.legacy_invalid_empty_selections_on_union(query)` to handle this scenario"
      end

      # This method is called during validation when a previously-allowed, but non-spec
      # query is encountered where a union field has no child selections on it.
      #
      # You should implement this method to log the violation so that you can contact clients
      # and notify them about changing their queries. Then return a suitable value to
      # tell GraphQL-Ruby how to continue.
      #
      # **Parameters**
      #
      # - `query` (`GraphQL::Query`)
      # - `type` (`Module`) — A GraphQL type definition
      #
      # **Returns**
      #
      # - `:return_validation_error` — Let GraphQL-Ruby return the (new) normal validation error for this query
      # - `String` — A validation error to return for this query
      # - `nil` — Don't send the client an error, continue the legacy behavior (allow this query to execute)
      #
      # :call-seq:
      #   legacy_invalid_empty_selections_on_union_with_type(GraphQL::Query query, Module type) -> :return_validation_error | String | nil
      def legacy_invalid_empty_selections_on_union_with_type(query, type)
        legacy_invalid_empty_selections_on_union(query)
      end

      # This setting controls how GraphQL-Ruby handles overlapping selections on scalar types when the types
      # don't match.
      #
      # When set to `false`, GraphQL-Ruby will reject those queries with a validation error (as per the GraphQL spec).
      #
      # When set to `true`, GraphQL-Ruby will call [.legacy_invalid_return_type_conflicts](rdoc-ref:.legacy_invalid_return_type_conflicts) when the scenario is encountered.
      #
      # **Parameters**
      #
      # - `new_value` (`Boolean`) — `true` permits the legacy behavior, `false` rejects it.
      #
      # **Returns**
      #
      # - `true, false, nil`
      #
      # :call-seq:
      #   allow_legacy_invalid_return_type_conflicts(bool new_value) -> true | false | nil
      def allow_legacy_invalid_return_type_conflicts(new_value = NOT_CONFIGURED)
        if NOT_CONFIGURED.equal?(new_value)
          if defined?(@allow_legacy_invalid_return_type_conflicts)
            @allow_legacy_invalid_return_type_conflicts
          else
            find_inherited_value(:allow_legacy_invalid_return_type_conflicts)
          end
        else
          @allow_legacy_invalid_return_type_conflicts = new_value
        end
      end

      # This method is called when the query contains fields which don't contain matching scalar types.
      # This was previously allowed by GraphQL-Ruby but it's a violation of the GraphQL spec.
      #
      # You should implement this method to log the violation so that you observe usage of these fields.
      # Fixing this scenario might mean adding new fields, and telling clients to use those fields.
      # (Changing the field return type would be a breaking change, but if it works for your client use cases,
      # that might work, too.)
      #
      # **Parameters**
      #
      # - `query` (`GraphQL::Query`)
      # - `type1` (`Module`) — A GraphQL type definition
      # - `type2` (`Module`) — A GraphQL type definition
      # - `node1` (`GraphQL::Language::Nodes::Field`) — This node is recognized as conflicting. You might call `.line` and `.col` for custom error reporting.
      # - `node2` (`GraphQL::Language::Nodes::Field`) — The other node recognized as conflicting.
      #
      # **Returns**
      #
      # - `:return_validation_error` — Let GraphQL-Ruby return the (new) normal validation error for this query
      # - `String` — A validation error to return for this query
      # - `nil` — Don't send the client an error, continue the legacy behavior (allow this query to execute)
      #
      # :call-seq:
      #   legacy_invalid_return_type_conflicts(GraphQL::Query query, Module type1, Module type2, GraphQL::Language::Nodes::Field node1, GraphQL::Language::Nodes::Field node2) -> :return_validation_error | String | nil
      def legacy_invalid_return_type_conflicts(query, type1, type2, node1, node2)
        raise "Implement #{self}.legacy_invalid_return_type_conflicts to handle this invalid selection"
      end

      # The legacy complexity implementation included several bugs:
      #
      # - In some cases, it used the lexically _last_ field to determine a cost, instead of calculating the maximum among selections
      # - In some cases, it called field complexity hooks repeatedly (when it should have only called them once)
      #
      # The future implementation may produce higher total complexity scores, so it's not active by default yet. You can opt into
      # the future default behavior by configuring `:future` here. Or, you can choose a mode for each query with [.complexity_cost_calculation_mode_for](rdoc-ref:.complexity_cost_calculation_mode_for).
      #
      # The legacy mode is currently maintained alongside the future one, but it will be removed in a future GraphQL-Ruby version.
      #
      # If you choose `:compare`, you must also implement [.legacy_complexity_cost_calculation_mismatch](rdoc-ref:.legacy_complexity_cost_calculation_mismatch) to handle the input somehow.
      #
      # **Examples**
      #
      # **Example: Opting into the future calculation mode**
      #
      # ```ruby
      # complexity_cost_calculation_mode(:future)
      # ```
      #
      # **Example: Choosing the legacy mode (which will work until that mode is removed...)**
      #
      # ```ruby
      # complexity_cost_calculation_mode(:legacy)
      # ```
      #
      # **Example: Run both modes for every query, call {.legacy_complexity_cost_calculation_mismatch} when they don't match:**
      #
      # ```ruby
      # complexity_cost_calculation_mode(:compare)
      # ```
      def complexity_cost_calculation_mode(new_mode = NOT_CONFIGURED)
        if NOT_CONFIGURED.equal?(new_mode)
          if defined?(@complexity_cost_calculation_mode)
            @complexity_cost_calculation_mode
          else
            find_inherited_value(:complexity_cost_calculation_mode)
          end
        else
          @complexity_cost_calculation_mode = new_mode
        end
      end

      # Implement this method to produce a per-query complexity cost calculation mode. (Technically, it's per-multiplex.)
      #
      # This is a way to check the compatibility of queries coming to your API without adding overhead of running `:compare`
      # for every query. You could sample traffic, turn it off/on with feature flags, or anything else.
      #
      # **Examples**
      #
      # **Example: Sampling traffic**
      #
      # ```ruby
      # def self.complexity_cost_calculation_mode_for(_context)
      #   if rand < 0.1 # 10% of the time
      #     :compare
      #   else
      #     :legacy
      #   end
      # end
      # ```
      #
      # **Example: Using a feature flag to manage future mode**
      #
      # ```ruby
      # def complexity_cost_calculation_mode_for(context)
      #   current_user = context[:current_user]
      #   if Flipper.enabled?(:future_complexity_cost, current_user)
      #     :future
      #   elsif rand < 0.5 # 50%
      #     :compare
      #   else
      #     :legacy
      #   end
      # end
      # ```
      #
      # **Parameters**
      #
      # - `multiplex_context` (`Hash`) — The context for the currently-running `Execution::Multiplex` (which contains one or more queries)
      #
      # **Returns**
      #
      # - `:future` — Use the new calculation algorithm -- may be higher than `:legacy`
      # - `:legacy` — Use the legacy calculation algorithm, warts and all
      # - `:compare` — Run both algorithms and call [.legacy_complexity_cost_calculation_mismatch](rdoc-ref:.legacy_complexity_cost_calculation_mismatch) if they don't match
      #
      # :call-seq:
      #   complexity_cost_calculation_mode_for(Hash multiplex_context) -> :future | :legacy | :compare
      def complexity_cost_calculation_mode_for(multiplex_context)
        complexity_cost_calculation_mode
      end

      # Implement this method in your schema to handle mismatches when `:compare` is used.
      #
      # See [Query::Context#add_error](rdoc-ref:Query::Context#add_error) Adding an error to the response to notify the client
      # See [Query::Context#response_extensions](rdoc-ref:Query::Context#response_extensions) Adding key-value pairs to the response `"extensions" => { ... }`
      #
      # **Examples**
      #
      # **Example: Logging the mismatch**
      #
      # ```ruby
      # def self.legacy_cost_calculation_mismatch(multiplex, future_cost, legacy_cost)
      #   client_id = multiplex.context[:api_client].id
      #   operation_names = multiplex.queries.map { |q| q.selected_operation_name || "anonymous" }.join(", ")
      #   Stats.increment(:complexity_mismatch, tags: { client: client_id, ops: operation_names })
      #   legacy_cost
      # end
      # ```
      #
      # **Parameters**
      #
      # - `multiplex` (`GraphQL::Execution::Multiplex`)
      # - `future_complexity_cost` (`Integer`)
      # - `legacy_complexity_cost` (`Integer`)
      #
      # **Returns**
      #
      # - `Integer` — the cost to use for this query (probably one of `future_complexity_cost` or `legacy_complexity_cost`)
      #
      # :call-seq:
      #   legacy_complexity_cost_calculation_mismatch(GraphQL::Execution::Multiplex multiplex, Integer future_complexity_cost, Integer legacy_complexity_cost) -> Integer
      def legacy_complexity_cost_calculation_mismatch(multiplex, future_complexity_cost, legacy_complexity_cost)
        raise "Implement #{self}.legacy_complexity_cost(multiplex, future_complexity_cost, legacy_complexity_cost) to handle this mismatch (#{future_complexity_cost} vs. #{legacy_complexity_cost}) and return a value to use"
      end

      private

      def add_trace_options_for(mode, new_options)
        if mode == :default
          own_trace_modes.each do |mode_name, t_class|
            if t_class <= DefaultTraceClass
              t_opts = trace_options_for(mode_name)
              t_opts.merge!(new_options)
            end
          end
        else
          t_opts = trace_options_for(mode)
          t_opts.merge!(new_options)
        end
        nil
      end

      # **Parameters**
      #
      # - `t` (`Module, Array<Module>`)
      #
      # **Returns**
      #
      # - `void`
      #
      # :call-seq:
      #   add_type_and_traverse(Module | Array[Module] t, root:) -> void
      def add_type_and_traverse(t, root:)
        if root
          @root_types ||= []
          @root_types << t
        end
        new_types = Array(t)
        addition = Schema::Addition.new(schema: self, own_types: own_types, new_types: new_types)
        addition.types.each do |name, types_entry| # rubocop:disable Development/ContextIsPassedCop -- build-time, not query-time
          if (prev_entry = own_types[name])
            prev_entries = case prev_entry
            when Array
              prev_entry
            when Module
              own_types[name] = [prev_entry]
            else
              raise "Invariant: unexpected prev_entry at #{name.inspect} when adding #{t.inspect}"
            end

            case types_entry
            when Array
              prev_entries.concat(types_entry)
              prev_entries.uniq! # in case any are being re-visited
            when Module
              if !prev_entries.include?(types_entry)
                prev_entries << types_entry
              end
            else
              raise "Invariant: unexpected types_entry at #{name} when adding #{t.inspect}"
            end
          else
            if types_entry.is_a?(Array)
              types_entry.uniq!
            end
            own_types[name] = types_entry
          end
        end

        own_possible_types.merge!(addition.possible_types) { |key, old_val, new_val| old_val + new_val }
        own_union_memberships.merge!(addition.union_memberships)

        addition.references.each { |thing, pointers|
          prev_refs = own_references_to[thing] || []
          own_references_to[thing] = prev_refs | pointers.to_a
        }

        addition.directives.each { |dir_class| own_directives[dir_class.graphql_name] = dir_class }

        addition.arguments_with_default_values.each do |arg|
          arg.validate_default_value
        end
      end

      def lazy_methods
        if !defined?(@lazy_methods)
          if inherited_map = find_inherited_value(:lazy_methods)
            # this isn't _completely_ inherited :S (Things added after `dup` won't work)
            @lazy_methods = inherited_map.dup
          else
            @lazy_methods = GraphQL::Execution::Lazy::LazyMethodMap.new
            @lazy_methods.set(GraphQL::Execution::Lazy, :value)
            @lazy_methods.set(GraphQL::Dataloader::Request, :load_with_deprecation_warning)
          end
        end
        @lazy_methods
      end

      def own_types
        @own_types ||= {}
      end

      def own_references_to
        @own_references_to ||= {}.compare_by_identity
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
        @own_possible_types ||= {}.compare_by_identity
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

      def own_multiplex_analyzers
        @own_multiplex_analyzers ||= []
      end

      # This is overridden in subclasses to check the inheritance chain
      def get_references_to(type_defn)
        own_references_to[type_defn]
      end
    end

    module SubclassGetReferencesTo
      def get_references_to(type_defn)
        own_refs = own_references_to[type_defn]
        inherited_refs = superclass.references_to(type_defn)
        if inherited_refs&.any?
          if own_refs&.any?
            own_refs + inherited_refs
          else
            inherited_refs
          end
        else
          own_refs
        end
      end
    end

    # Install these here so that subclasses will also install it.
    self.connections = GraphQL::Pagination::Connections.new(schema: self)

    module DefaultTraceClass # :nodoc:
    end
  end
end

require "graphql/schema/loader"
require "graphql/schema/printer"
