# frozen_string_literal: true
require "graphql/schema/field/connection_extension"
require "graphql/schema/field/scope_extension"

module GraphQL
  class Schema
    # Field definitions are the primary way to expose data from an object type.
    # This API reference was migrated from guides/fields/introduction.md.
    # Keep field-specific behavior and examples here; the guide is only an
    # entry point for the broader fields documentation.
    #
    # Object fields expose data about that object or connect the object to other objects. You can add fields to your object types with the `field(...)` class method, for example:
    #
    # ```ruby
    # field :name, String, "The unique name of this list", null: false
    # ```
    #
    # [Objects](/type_definitions/objects) and [Interfaces](/type_definitions/interfaces) have fields.
    #
    # The different elements of field definition are addressed below:
    #
    # - [Names](#class-graphql-schema-field-field-names) identify the field in GraphQL
    # - [Return types](#class-graphql-schema-field-field-return-type) say what kind of data this field returns
    # - [Documentation](#class-graphql-schema-field-field-documentation) includes description, comments and deprecation notes
    # - [Resolution behavior](#class-graphql-schema-field-field-resolution) hooks up the GraphQL field to Ruby code
    # - [Arguments](#class-graphql-schema-field-field-arguments) allow fields to take input when they're queried
    # - [Extra field metadata](#class-graphql-schema-field-extra-field-metadata) for low-level access to the GraphQL-Ruby runtime
    # - [Add default values for field parameters](#class-graphql-schema-field-field-parameter-default-values)
    #
    # ## Field Names
    #
    # A field's name is provided as the first argument or as the `name:` option:
    #
    # ```ruby
    # field :team_captain, ...
    # # or:
    # field ..., name: :team_captain
    # ```
    #
    # Under the hood, GraphQL-Ruby **camelizes** field names, so `field :team_captain, ...` would be `{ teamCaptain }` in GraphQL. You can disable this behavior by adding `camelize: false` to your field definition or to the [default field options](#class-graphql-schema-field-field-parameter-default-values).
    #
    # The field's name is also used as the basis of [field resolution](#class-graphql-schema-field-field-resolution).
    #
    # ## Field Return Type
    #
    # The second argument to `field(...)` is the return type. This can be:
    #
    # - A built-in GraphQL type (`Integer`, `Float`, `String`, `ID`, or `Boolean`)
    # - A GraphQL type from your application
    # - An _array_ of any of the above, which denotes a [list type](/type_definitions/lists).
    #
    # [Nullability](/type_definitions/non_nulls) is expressed with the `null:` keyword:
    #
    # - `null: true` (default) means that the field _may_ return `nil`
    # - `null: false` means the field is non-nullable; it may not return `nil`. If the implementation returns `nil`, GraphQL-Ruby will return an error to the client.
    #
    # Additionally, list types maybe nullable by adding `[..., null: true]` to the definition.
    #
    # Here are some examples:
    #
    # ```ruby
    # field :name, String # `String`, may return a `String` or `nil`
    # field :id, ID, null: false # `ID!`, always returns an `ID`, never `nil`
    # field :teammates, [Types::User], null: false # `[User!]!`, always returns a list containing `User`s
    # field :scores, [Integer, null: true] # `[Int]`, may return a list or `nil`, the list may contain a mix of `Integer`s and `nil`s
    # ```
    #
    # ## Field Documentation
    #
    # Fields may be documented with a __description__, __comment__ and may be __deprecated__.
    #
    # __Descriptions__ can be added with the `field(...)` method as a positional argument, a keyword argument, or inside the block:
    #
    # ```ruby
    # # 3rd positional argument
    # field :name, String, "The name of this thing", null: false
    #
    # # `description:` keyword
    # field :name, String, null: false,
    #   description: "The name of this thing"
    #
    # # inside the block
    # field :name, String, null: false do
    #   description "The name of this thing"
    # end
    # ```
    #
    # __Comments__ can be added with the `field(...)` method as a keyword argument, or inside the block:
    # ```ruby
    # # `comment:` keyword
    # field :name, String, null: false, comment: "Rename to full name"
    #
    # # inside the block
    # field :name, String, null: false do
    #   comment "Rename to full name"
    # end
    # ```
    #
    # Generates field name with comment above "Rename to full name" above.
    #
    # ```graphql
    # type Foo {
    #     # Rename to full name
    #     name: String!
    # }
    # ```
    #
    # __Deprecated__ fields can be marked by adding a `deprecation_reason:` keyword argument:
    #
    # ```ruby
    # field :email, String,
    #   deprecation_reason: "Users may have multiple emails, use `User.emails` instead."
    # ```
    #
    # Fields with a `deprecation_reason:` will appear as "deprecated" in GraphiQL.
    #
    # ## Field Resolution
    #
    # In general, fields return Ruby values corresponding to their GraphQL return types. For example, a field with the return type `String` should return a Ruby string, and a field with the return type `[User!]!` should return a Ruby array with zero or more `User` objects in it.
    #
    # By default, fields return values by:
    #
    # - Trying to call a method on the underlying object; _OR_
    # - If the underlying object is a `Hash`, lookup a key in that hash.
    # - An optional `:fallback_value` can be supplied that will be used if the above fail.
    #
    # The method name or hash key corresponds to the field name, so in this example:
    #
    # ```ruby
    # field :top_score, Integer, null: false
    # ```
    #
    # The default behavior is to look for a `#top_score` method, or lookup a `Hash` key, `:top_score` (symbol) or `"top_score"` (string).
    #
    # You can override the method name with the `method:` keyword, or override the hash key(s) with the `hash_key:` or `dig:` keyword, for example:
    #
    # ```ruby
    # # Use the `#best_score` method to resolve this field
    # field :top_score, Integer, null: false,
    #   method: :best_score
    #
    # # Lookup `hash["allPlayers"]` to resolve this field
    # field :players, [User], null: false,
    #   hash_key: "allPlayers"
    #
    # # Use the `#dig` method on the hash with `:nested` and `:movies` keys
    # field :movies, [Movie], null: false,
    #   dig: [:nested, :movies]
    # ```
    #
    # To pass-through the underlying object without calling a method on it, you can use `method: :itself`:
    #
    # ```ruby
    # field :player, User, null: false,
    #   method: :itself
    # ```
    #
    # This is equivalent to:
    #
    # ```ruby
    # field :player, User, null: false
    #
    # def player
    #   object
    # end
    # ```
    #
    # If you don't want to delegate to the underlying object, you can define a method for each field:
    #
    # ```ruby
    # # Use the custom method below to resolve this field
    # field :total_games_played, Integer, null: false
    #
    # def total_games_played
    #   object.games.count
    # end
    # ```
    #
    # Inside the method, you can access some helper methods:
    #
    # - `object` is the underlying application object (formerly `obj` to resolve functions)
    # - `context` is the query context (passed as `context:` when executing queries, formerly `ctx` to resolve functions)
    #
    # Additionally, when you define arguments (see below), they're passed to the method definition, for example:
    #
    # ```ruby
    # # Call the custom method with incoming arguments
    # field :current_winning_streak, Integer, null: false do
    #   argument :include_ties, Boolean, required: false, default_value: false
    # end
    #
    # def current_winning_streak(include_ties:)
    #   # Business logic goes here
    # end
    # ```
    #
    # As the examples above show, by default the custom method name must match the field name. If you want to use a different custom method, the `resolver_method` option is available:
    #
    # ```ruby
    # # Use the custom method with a non-default name below to resolve this field
    # field :total_games_played, Integer, null: false, resolver_method: :games_played
    #
    # def games_played
    #   object.games.count
    # end
    # ```
    #
    # `resolver_method` has two main use cases:
    #
    # 1. resolver re-use between multiple fields
    # 2. dealing with method conflicts (specifically if you have fields named `context` or `object`)
    #
    # Note that `resolver_method` _cannot_ be used in combination with `method` or `hash_key`.
    #
    # ## Field Arguments
    #
    # _Arguments_ allow fields to take input to their resolution. For example:
    #
    # - A `search()` field may take a `term:` argument, which is the query to use for searching, eg `search(term: "GraphQL")`
    # - A `user()` field may take an `id:` argument, which specifies which user to find, eg `user(id: 1)`
    # - An `attachments()` field may take a `type:` argument, which filters the result by file type, eg `attachments(type: PHOTO)`
    #
    # Read more in the [Arguments guide](/fields/arguments)
    #
    # ## Extra Field Metadata
    #
    # Inside a field method, you can access some low-level objects from the GraphQL-Ruby runtime. Be warned, these APIs are subject to change, so check the changelog when updating.
    #
    # A few `extras` are available:
    #
    # - `ast_node`
    # - `graphql_name` (the field's name)
    # - `owner` (the type that this field belongs to)
    # - `lookahead` (see [Lookahead](/queries/lookahead))
    # - `execution_errors`, whose `#add(err_or_msg)` method should be used for adding errors
    # - `argument_details` (Interpreter only), an instance of [GraphQL::Execution::Interpreter::Arguments](rdoc-ref:GraphQL::Execution::Interpreter::Arguments) with argument metadata
    # - `parent` (the previous `object` in the query)
    # - Custom extras, see below
    #
    # To inject them into your field method, first, add the `extras:` option to the field definition:
    #
    # ```ruby
    # field :my_field, String, null: false, extras: [:ast_node]
    # ```
    #
    # Then add `ast_node:` keyword to the method signature:
    #
    # ```ruby
    # def my_field(ast_node:)
    #   # ...
    # end
    # ```
    #
    # At runtime, the requested runtime object will be passed to the field.
    #
    # __Custom extras__ are also possible. Any method on your field class can be passed to `extras: [...]`, and the value will be injected into the method. For example, `extras: [:owner]` will inject the object type who owns the field. Any new methods on your custom field class may be used, too.
    #
    # ## Field Parameter Default Values
    #
    # The field method requires you to pass `null:` keyword argument to determine whether the field is nullable or not. For another field you may want to override `camelize`, which is `true` by default. You can override this behavior by adding a custom field with overwritten `camelize` option, which is `true` by default.
    #
    # ```ruby
    # class CustomField < GraphQL::Schema::Field
    #   # Add `null: false` and `camelize: false` which provide default values
    #   # in case the caller doesn't pass anything for those arguments.
    #   # **kwargs is a catch-all that will get everything else
    #   def initialize(*args, null: false, camelize: false, **kwargs, &block)
    #     # Then, call super _without_ any args, where Ruby will take
    #     # _all_ the args originally passed to this method and pass it to the super method.
    #     super
    #   end
    # end
    # ```
    #
    # To use `CustomField` in your Objects and Interfaces, you'll need to register it as a `field_class` on those classes. See  [Customizing Fields](https://graphql-ruby.org/type_definitions/extensions#customizing-fields) for more information on how to do so.
    #
    class Field
      include GraphQL::Schema::Member::HasArguments
      include GraphQL::Schema::Member::HasArguments::FieldConfigured
      include GraphQL::Schema::Member::HasAstNode
      include GraphQL::Schema::Member::HasAuthorization
      include GraphQL::Schema::Member::HasPath
      include GraphQL::Schema::Member::HasValidators
      extend GraphQL::Schema::FindInheritedValue
      include GraphQL::EmptyObjects
      include GraphQL::Schema::Member::HasDirectives
      include GraphQL::Schema::Member::HasDeprecationReason

      class FieldImplementationFailed < GraphQL::Error; end

      # **Returns**
      #
      # - `String` — the GraphQL name for this field, camelized unless `camelize: false` is provided
      attr_reader :name
      alias :graphql_name :name

      attr_writer :description

      # **Returns**
      #
      # - `Symbol` — Method or hash key on the underlying object to look up
      attr_reader :method_sym

      # **Returns**
      #
      # - `String` — Method or hash key on the underlying object to look up
      attr_reader :method_str

      attr_reader :hash_key
      attr_reader :dig_keys

      # **Returns**
      #
      # - `Symbol` — The method on the type to look up
      #
      # :call-seq:
      #   resolver_method() -> Symbol
      def resolver_method
        if @resolver_class
          @resolver_class.resolver_method
        else
          @resolver_method
        end
      end

      # **Returns**
      #
      # - `String, nil`
      #
      # :call-seq:
      #   deprecation_reason() -> String | nil
      def deprecation_reason
        super || @resolver_class&.deprecation_reason
      end

      def directives
        if @resolver_class && !(r_dirs = @resolver_class.directives).empty?
          if !(own_dirs = super).empty?
            new_dirs = own_dirs.dup
            r_dirs.each do |r_dir|
              if r_dir.class.repeatable? ||
                ( (r_dir_name = r_dir.graphql_name) &&
                  (!new_dirs.any? { |d| d.graphql_name == r_dir_name })
                )
                new_dirs << r_dir
              end
            end
            new_dirs
          else
            r_dirs
          end
        else
          super
        end
      end

      # **Returns**
      #
      # - `Class` — The thing this field was defined on (type, mutation, resolver)
      attr_accessor :owner

      # **Returns**
      #
      # - `Class` — The GraphQL type this field belongs to. (For fields defined on mutations, it's the payload type)
      #
      # :call-seq:
      #   owner_type() -> Class
      def owner_type
        @owner_type ||= if owner.nil?
          raise GraphQL::InvariantError, "Field #{original_name.inspect} (graphql name: #{graphql_name.inspect}) has no owner, but all fields should have an owner. How did this happen?!"
        elsif owner < GraphQL::Schema::Mutation
          owner.payload_type
        else
          owner
        end
      end

      # **Returns**
      #
      # - `Symbol` — the original name of the field, passed in by the user
      attr_reader :original_name

      # **Returns**
      #
      # - `Class, nil` — The [Schema::Resolver](rdoc-ref:Schema::Resolver) this field was derived from, if there is one
      #
      # :call-seq:
      #   resolver() -> Class | nil
      def resolver
        @resolver_class
      end

      # **Returns**
      #
      # - `Boolean` — Is this field a predefined introspection field?
      #
      # :call-seq:
      #   introspection?() -> bool
      def introspection?
        @introspection
      end

      def inspect
        "#<#{self.class} #{path}#{!all_argument_definitions.empty? ? "(...)" : ""}: #{type.to_type_signature}>"
      end

      alias :mutation :resolver

      # **Returns**
      #
      # - `Boolean` — Apply tracing to this field? (Default: skip scalars, this is the override value)
      attr_reader :trace

      # **Returns**
      #
      # - `String, nil`
      #
      # :call-seq:
      #   subscription_scope() -> String | nil
      def subscription_scope
        @subscription_scope || (@resolver_class.respond_to?(:subscription_scope) ? @resolver_class.subscription_scope : nil)
      end
      attr_writer :subscription_scope

      # Can be set with `connection: true|false` or inferred from a type name ending in `*Connection`
      #
      # **Returns**
      #
      # - `Boolean` — if true, this field will be wrapped with Relay connection behavior
      #
      # :call-seq:
      #   connection?() -> bool
      def connection?
        if @connection.nil?
          # Provide default based on type name
          return_type_name = if @return_type_expr
            Member::BuildType.to_type_name(@return_type_expr)
          elsif @resolver_class && @resolver_class.type
            Member::BuildType.to_type_name(@resolver_class.type)
          elsif type
            # As a last ditch, try to force loading the return type:
            type.unwrap.name
          end
          if return_type_name
            @connection = return_type_name.end_with?("Connection") && return_type_name != "Connection"
          else
            # TODO set this when type is set by method
            false # not loaded yet?
          end
        else
          @connection
        end
      end

      # **Returns**
      #
      # - `Boolean` — if true, the return type's `.scope_items` method will be applied to this field's return value
      #
      # :call-seq:
      #   scoped?() -> bool
      def scoped?
        if !@scope.nil?
          # The default was overridden
          @scope
        elsif @return_type_expr
          # Detect a list return type, but don't call `type` since that may eager-load an otherwise lazy-loaded type
          @return_type_expr.is_a?(Array) ||
            (@return_type_expr.is_a?(String) && @return_type_expr.include?("[")) ||
            connection?
        elsif @resolver_class
          resolver_type = @resolver_class.type_expr
          resolver_type.is_a?(Array) ||
            (resolver_type.is_a?(String) && resolver_type.include?("[")) ||
            connection?
        else
          false
        end
      end

      # This extension is applied to fields when [connection?](rdoc-ref:#connection?) is true.
      #
      # You can override it in your base field definition.
      #
      # **Returns**
      #
      # - `Class` — A [FieldExtension](rdoc-ref:FieldExtension) subclass for implementing pagination behavior.
      #
      # **Examples**
      #
      # **Example: Configuring a custom extension**
      #
      # ```ruby
      # class Types::BaseField < GraphQL::Schema::Field
      #   connection_extension(MyCustomExtension)
      # end
      # ```
      #
      # :call-seq:
      #   connection_extension(new_extension_class) -> Class
      def self.connection_extension(new_extension_class = nil)
        if new_extension_class
          @connection_extension = new_extension_class
        else
          @connection_extension ||= find_inherited_value(:connection_extension, ConnectionExtension)
        end
      end

      # **Returns**
      #
      # - `Object` — Boolean
      attr_reader :relay_node_field
      # **Returns**
      #
      # - `Object` — Boolean
      attr_reader :relay_nodes_field

      # **Returns**
      #
      # - `Boolean` — Should we warn if this field's name conflicts with a built-in method?
      #
      # :call-seq:
      #   method_conflict_warning?() -> bool
      def method_conflict_warning?
        @method_conflict_warning
      end

      # **Parameters**
      #
      # - `name` (`Symbol`) — The underscore-cased version of this field name (will be camelized for the GraphQL API)
      # - `type` (`Class, GraphQL::BaseType, Array`) — The return type of this field
      # - `owner` (`Class`) — The type that this field belongs to
      # - `null` (`Boolean`) — (defaults to `true`) `true` if this field may return `null`, `false` if it is never `null`
      # - `description` (`String`) — Field description
      # - `comment` (`String`) — Field comment
      # - `deprecation_reason` (`String`) — If present, the field is marked "deprecated" with this message
      # - `method` (`Symbol`) — The method to call on the underlying object to resolve this field (defaults to `name`)
      # - `hash_key` (`String, Symbol`) — The hash key to lookup on the underlying object (if its a Hash) to resolve this field (defaults to `name` or `name.to_s`)
      # - `dig` (`Array<String, Symbol>`) — The nested hash keys to lookup on the underlying hash to resolve this field using dig
      # - `resolver_method` (`Symbol`) — The method on the type to call to resolve this field (defaults to `name`)
      # - `connection` (`Boolean`) — `true` if this field should get automagic connection behavior; default is to infer by `*Connection` in the return type name
      # - `connection_extension` (`Class`) — The extension to add, to implement connections. If `nil`, no extension is added.
      # - `resolve_static` (`Symbol, true, nil`) — Used by `Schema.execute_next` to produce a single value, shared by all objects which resolve this field. Called on the owner type class with `context, **arguments`
      # - `resolve_batch` (`Symbol, true, nil`) — Used by `Schema.execute_next` map `objects` to a same-sized Array of results. Called on the owner type class with `objects, context, **arguments`.
      # - `resolve_each` (`Symbol, true, nil`) — Used by `Schema.execute_next` to get a value value for each item. Called on the owner type class with `object, context, **arguments`.
      # - `resolve_legacy_instance_method` (`Symbol, true, nil`) — Used by `Schema.execute_next` to get a value value for each item. Calls an instance method on the object type class.
      # - `dataload` (`Class, Hash`) — Shorthand for making dataloader calls
      # - `max_page_size` (`Integer, nil`) — For connections, the maximum number of items to return from this field, or `nil` to allow unlimited results.
      # - `default_page_size` (`Integer, nil`) — For connections, the default number of items to return from this field, or `nil` to return unlimited results.
      # - `introspection` (`Boolean`) — If true, this field will be marked as `#introspection?` and the name may begin with `__`
      # - `resolver_class` (`Class`) — (Private) A [Schema::Resolver](rdoc-ref:Schema::Resolver) which this field was derived from. Use `resolver:` to create a field with a resolver.
      # - `arguments` (`{String=>GraphQL::Schema::Argument, Hash}`) — Arguments for this field (may be added in the block, also)
      # - `camelize` (`Boolean`) — If true, the field name will be camelized when building the schema
      # - `complexity` (`Numeric`) — When provided, set the complexity for this field
      # - `scope` (`Boolean`) — If true, the return type's `.scope_items` method will be called on the return value
      # - `subscription_scope` (`Symbol, String`) — A key in `context` which will be used to scope subscription payloads
      # - `extensions` (`Array<Class, Hash<Class => Object>>`) — Named extensions to apply to this field (see also [extension](rdoc-ref:GraphQL::Schema::Field#extension))
      # - `directives` (`Hash{Class => Hash}`) — Directives to apply to this field
      # - `trace` (`Boolean`) — If true, a [GraphQL::Tracing](rdoc-ref:GraphQL::Tracing) tracer will measure this scalar field
      # - `broadcastable` (`Boolean`) — Whether or not this field can be distributed in subscription broadcasts
      # - `ast_node` (`Language::Nodes::FieldDefinition, nil`) — If this schema was parsed from definition, this AST node defined the field
      # - `method_conflict_warning` (`Boolean`) — If false, skip the warning if this field's method conflicts with a built-in method
      # - `validates` (`Array<Hash>`) — Configurations for validating this field
      # - `fallback_value` (`Object`) — A fallback value if the method is not defined
      # - `dynamic_introspection` (`Boolean`) — (Private, used by GraphQL-Ruby)
      # - `relay_node_field` (`Boolean`) — (Private, used by GraphQL-Ruby)
      # - `relay_nodes_field` (`Boolean`) — (Private, used by GraphQL-Ruby)
      # - `extras` (`Array<:ast_node, :parent, :lookahead, :owner, :execution_errors, :graphql_name, :argument_details, Symbol>`) — Extra arguments to be injected into the resolver for this field
      # - `definition_block` (`Proc`) — an additional block for configuring the field. Receive the field as a block param, or, if no block params are defined, then the block is `instance_eval`'d on the new [Field](rdoc-ref:Field).
      #
      # :call-seq:
      #   initialize(Class | GraphQL::BaseType | Array type:, Symbol name:, Class owner:, bool null:, String description:, String comment:, String deprecation_reason:, Symbol method:, Symbol | true | nil resolve_legacy_instance_method:, Symbol | true | nil resolve_static:, Symbol | true | nil resolve_each:, Symbol | true | nil resolve_batch:, String | Symbol hash_key:, Array[String | Symbol] dig:, Symbol resolver_method:, bool connection:, Integer | nil max_page_size:, Integer | nil default_page_size:, bool scope:, bool introspection:, bool camelize:, bool trace:, Numeric complexity:, Class | Hash dataload:, Language::Nodes::FieldDefinition | nil ast_node:, Array[:ast_node | :parent | :lookahead | :owner | :execution_errors | :graphql_name | :argument_details | Symbol] extras:, Array[Class | Hash[Class, Object]] extensions:, Class connection_extension:, Class resolver_class:, Symbol | String subscription_scope:, bool relay_node_field:, bool relay_nodes_field:, bool method_conflict_warning:, bool broadcastable:, {String=>GraphQL::Schema::Argument | Hash} arguments:, Hash[Class, Hash] directives:, Array[Hash] validates:, Object fallback_value:, bool dynamic_introspection:, Proc &definition_block)
      def initialize(type: nil, name: nil, owner: nil, null: nil, description: NOT_CONFIGURED, comment: NOT_CONFIGURED, deprecation_reason: nil, method: nil, resolve_legacy_instance_method: nil, resolve_static: nil, resolve_each: nil, resolve_batch: nil, hash_key: nil, dig: nil, resolver_method: nil, connection: nil, max_page_size: NOT_CONFIGURED, default_page_size: NOT_CONFIGURED, scope: nil, introspection: false, camelize: true, trace: nil, complexity: nil, dataload: nil, ast_node: nil, extras: EMPTY_ARRAY, extensions: EMPTY_ARRAY, connection_extension: self.class.connection_extension, resolver_class: nil, subscription_scope: nil, relay_node_field: false, relay_nodes_field: false, method_conflict_warning: true, broadcastable: NOT_CONFIGURED, arguments: EMPTY_HASH, directives: EMPTY_HASH, validates: EMPTY_ARRAY, fallback_value: NOT_CONFIGURED, dynamic_introspection: false, &definition_block)
        if name.nil?
          raise ArgumentError, "missing first `name` argument or keyword `name:`"
        end
        if !(resolver_class)
          if type.nil? && !block_given?
            raise ArgumentError, "missing second `type` argument, keyword `type:`, or a block containing `type(...)`"
          end
        end
        @original_name = name
        name_s = -name.to_s

        @underscored_name = -Member::BuildType.underscore(name_s)
        @name = -(camelize ? Member::BuildType.camelize(name_s) : name_s)
        NameValidator.validate!(@name)
        @description = description
        @comment = comment
        @type = @owner_type = @own_validators = @own_directives = @own_arguments = @arguments_statically_coercible = nil # these will be prepared later if necessary

        self.deprecation_reason = deprecation_reason

        if method && hash_key && dig
          raise ArgumentError, "Provide `method:`, `hash_key:` _or_ `dig:`, not multiple. (called with: `method: #{method.inspect}, hash_key: #{hash_key.inspect}, dig: #{dig.inspect}`)"
        end

        if resolver_method
          if method
            raise ArgumentError, "Provide `method:` _or_ `resolver_method:`, not both. (called with: `method: #{method.inspect}, resolver_method: #{resolver_method.inspect}`)"
          end

          if hash_key || dig
            raise ArgumentError, "Provide `hash_key:`, `dig:`, _or_ `resolver_method:`, not multiple. (called with: `hash_key: #{hash_key.inspect}, dig: #{dig.inspect}, resolver_method: #{resolver_method.inspect}`)"
          end
        end

        method_name = method || hash_key || name_s
        @dig_keys = dig
        if hash_key
          @hash_key = hash_key
          @hash_key_str = hash_key.to_s
        else
          @hash_key = NOT_CONFIGURED
          @hash_key_str = NOT_CONFIGURED
        end

        @method_str = -method_name.to_s
        @method_sym = method_name.to_sym
        @resolver_method = (resolver_method || name_s).to_sym

        if resolve_static
          @execution_mode = :resolve_static
          @execution_mode_key = resolve_static == true ? @method_sym : resolve_static
        elsif resolve_batch
          @execution_mode = :resolve_batch
          @execution_mode_key = resolve_batch == true ? @method_sym : resolve_batch
        elsif resolve_each
          @execution_mode = :resolve_each
          @execution_mode_key = resolve_each == true ? @method_sym : resolve_each
        elsif hash_key
          @execution_mode = :hash_key
          @execution_mode_key = hash_key
        elsif dig
          @execution_mode = :dig
          @execution_mode_key = dig
        elsif resolver_class
          @execution_mode = :resolver_class
          @execution_mode_key = resolver_class
        elsif resolve_legacy_instance_method
          @execution_mode = :resolve_legacy_instance_method
          @execution_mode_key = resolve_legacy_instance_method == true ? @method_sym : resolve_legacy_instance_method
        elsif dataload
          @execution_mode = :dataload
          @execution_mode_key = dataload
        else
          @execution_mode = :direct_send
          @execution_mode_key = @method_sym
        end

        @complexity = complexity
        @dynamic_introspection = dynamic_introspection
        @return_type_expr = type
        @return_type_null = if !null.nil?
          null
        elsif resolver_class
          nil
        else
          true
        end
        @connection = connection
        @max_page_size = max_page_size
        @default_page_size = default_page_size
        @introspection = introspection
        @extras = extras
        @broadcastable = broadcastable
        @resolver_class = resolver_class
        @scope = scope
        @trace = trace
        @relay_node_field = relay_node_field
        @relay_nodes_field = relay_nodes_field
        @ast_node = ast_node
        @method_conflict_warning = method_conflict_warning
        @fallback_value = fallback_value
        @definition_block = definition_block

        arguments.each do |name, arg|
          case arg
          when Hash
            argument(name: name, **arg)
          when GraphQL::Schema::Argument
            add_argument(arg)
          when Array
            arg.each { |a| add_argument(a) }
          else
            raise ArgumentError, "Unexpected argument config (#{arg.class}): #{arg.inspect}"
          end
        end

        @owner = owner
        @subscription_scope = subscription_scope

        @extensions = EMPTY_ARRAY
        @call_after_define = false
        set_pagination_extensions(connection_extension: NOT_CONFIGURED.equal?(connection_extension) ? self.class.connection_extension : connection_extension)
        # Do this last so we have as much context as possible when initializing them:
        if !extensions.empty?
          self.extensions(extensions)
        end

        if resolver_class && !resolver_class.extensions.empty?
          self.extensions(resolver_class.extensions)
        end

        if !directives.empty?
          directives.each do |(dir_class, options)|
            self.directive(dir_class, **options)
          end
        end

        if !validates.empty?
          self.validates(validates)
        end

        if @definition_block.nil?
          self.extensions.each(&:after_define_apply)
          @call_after_define = true
        end
      end

      attr_reader :execution_mode_key, :execution_mode # :nodoc:

      # Calls the definition block, if one was given.
      # This is deferred so that references to the return type
      # can be lazily evaluated, reducing Rails boot time.
      #
      # **Returns**
      #
      # - `self`
      def ensure_loaded # :nodoc:
        if @definition_block
          if @definition_block.arity == 1
            @definition_block.call(self)
          else
            instance_exec(self, &@definition_block)
          end
          self.extensions.each(&:after_define_apply)
          @call_after_define = true
          @definition_block = nil
        end
        self
      end

      attr_accessor :dynamic_introspection

      # If true, subscription updates with this field can be shared between viewers
      # See `GraphQL::Subscriptions::BroadcastAnalyzer`.
      #
      # **Returns**
      #
      # - `Boolean, nil`
      #
      # :call-seq:
      #   broadcastable?() -> bool | nil
      def broadcastable?
        if !NOT_CONFIGURED.equal?(@broadcastable)
          @broadcastable
        elsif @resolver_class
          @resolver_class.broadcastable?
        else
          nil
        end
      end

      # **Parameters**
      #
      # - `text` (`String`)
      #
      # **Returns**
      #
      # - `String`
      #
      # :call-seq:
      #   description(String text) -> String
      def description(text = nil)
        if text
          @description = text
        elsif !NOT_CONFIGURED.equal?(@description)
          @description
        elsif @resolver_class
          @resolver_class.description
        else
          nil
        end
      end

      # **Parameters**
      #
      # - `text` (`String`)
      #
      # **Returns**
      #
      # - `String, nil`
      #
      # :call-seq:
      #   comment(String text) -> String | nil
      def comment(text = nil)
        if text
          @comment = text
        elsif !NOT_CONFIGURED.equal?(@comment)
          @comment
        elsif @resolver_class
          @resolver_class.comment
        else
          nil
        end
      end

      # Read extension instances from this field,
      # or add new classes/options to be initialized on this field.
      # Extensions are executed in the order they are added.
      #
      # **Examples**
      #
      # **Example: adding an extension**
      #
      # ```ruby
      # extensions([MyExtensionClass])
      # ```
      #
      # **Example: adding multiple extensions**
      #
      # ```ruby
      # extensions([MyExtensionClass, AnotherExtensionClass])
      # ```
      #
      # **Example: adding an extension with options**
      #
      # ```ruby
      # extensions([MyExtensionClass, { AnotherExtensionClass => { filter: true } }])
      # ```
      #
      # **Parameters**
      #
      # - `extensions` (`Array<Class, Hash<Class => Hash>>`) — Add extensions to this field. For hash elements, only the first key/value is used.
      #
      # **Returns**
      #
      # - `Array<GraphQL::Schema::FieldExtension>` — extensions to apply to this field
      #
      # :call-seq:
      #   extensions(new_extensions) -> Array[GraphQL::Schema::FieldExtension]
      def extensions(new_extensions = nil)
        if new_extensions
          new_extensions.each do |extension_config|
            if extension_config.is_a?(Hash)
              extension_class, options = *extension_config.to_a[0]
              self.extension(extension_class, **options)
            else
              self.extension(extension_config)
            end
          end
        end
        @extensions
      end

      # Add `extension` to this field, initialized with `options` if provided.
      #
      # **Examples**
      #
      # **Example: adding an extension**
      #
      # ```ruby
      # extension(MyExtensionClass)
      # ```
      #
      # **Example: adding an extension with options**
      #
      # ```ruby
      # extension(MyExtensionClass, filter: true)
      # ```
      #
      # **Parameters**
      #
      # - `extension_class` (`Class`) — subclass of [Schema::FieldExtension](rdoc-ref:Schema::FieldExtension)
      # - `options` (`Hash`) — if provided, given as `options:` when initializing `extension`.
      #
      # **Returns**
      #
      # - `void`
      #
      # :call-seq:
      #   extension(Class extension_class, Hash **options) -> void
      def extension(extension_class, **options)
        extension_inst = extension_class.new(field: self, options: options)
        if @extensions.frozen?
          @extensions = @extensions.dup
        end
        if @call_after_define
          extension_inst.after_define_apply
        end
        @extensions << extension_inst
        nil
      end

      # Read extras (as symbols) from this field,
      # or add new extras to be opted into by this field's resolver.
      #
      # **Parameters**
      #
      # - `new_extras` (`Array<Symbol>`) — Add extras to this field
      #
      # **Returns**
      #
      # - `Array<Symbol>`
      #
      # :call-seq:
      #   extras(Array[Symbol] new_extras) -> Array[Symbol]
      def extras(new_extras = nil)
        if new_extras.nil?
          # Read the value
          field_extras = @extras
          if @resolver_class && !@resolver_class.extras.empty?
            field_extras + @resolver_class.extras
          else
            field_extras
          end
        else
          if @extras.frozen?
            @extras = @extras.dup
          end
          # Append to the set of extras on this field
          @extras.concat(new_extras)
        end
      end

      def calculate_complexity(query:, nodes:, child_complexity:)
        if respond_to?(:complexity_for)
          lookahead = GraphQL::Execution::Lookahead.new(query: query, field: self, ast_nodes: nodes, owner_type: owner)
          complexity_for(child_complexity: child_complexity, query: query, lookahead: lookahead)
        elsif connection?
          arguments = query.arguments_for(nodes.first, self)
          max_possible_page_size = nil
          if arguments.respond_to?(:[]) # It might have been an error
            if arguments[:first]
              max_possible_page_size = arguments[:first]
            end

            if arguments[:last] && (max_possible_page_size.nil? || arguments[:last] > max_possible_page_size)
              max_possible_page_size = arguments[:last]
            end
          elsif arguments.is_a?(GraphQL::ExecutionError) || arguments.is_a?(GraphQL::UnauthorizedError)
            raise arguments
          end

          if max_possible_page_size.nil?
            max_possible_page_size = default_page_size || query.schema.default_page_size || max_page_size || query.schema.default_max_page_size
          end

          if max_possible_page_size.nil?
            raise GraphQL::Error, "Can't calculate complexity for #{path}, no `first:`, `last:`, `default_page_size`, `max_page_size` or `default_max_page_size`"
          else
            metadata_complexity = 0
            lookahead = GraphQL::Execution::Lookahead.new(query: query, field: self, ast_nodes: nodes, owner_type: owner)

            lookahead.selections.each do |next_lookahead|
              # this includes `pageInfo`, `nodes` and `edges` and any custom fields
              # TODO this doesn't support procs yet -- unlikely to need it.
              metadata_complexity += next_lookahead.field.complexity
              if next_lookahead.name != :nodes && next_lookahead.name != :edges
                # subfields, eg, for pageInfo -- assumes no subselections
                metadata_complexity += next_lookahead.selections.size
              end
            end

            # Possible bug: selections on `edges` and `nodes` are _both_ multiplied here. Should they be?
            items_complexity = child_complexity - metadata_complexity
            subfields_complexity = (max_possible_page_size * items_complexity) + metadata_complexity
            # Apply this field's own complexity
            apply_own_complexity_to(subfields_complexity, query, nodes)
          end
        else
          apply_own_complexity_to(child_complexity, query, nodes)
        end
      end

      def complexity(new_complexity = nil)
        case new_complexity
        when Proc
          if new_complexity.parameters.size != 3
            fail(
              "A complexity proc should always accept 3 parameters: ctx, args, child_complexity. "\
              "E.g.: complexity ->(ctx, args, child_complexity) { child_complexity * args[:limit] }"
            )
          else
            @complexity = new_complexity
          end
        when Numeric
          @complexity = new_complexity
        when nil
          if @resolver_class
            @complexity || @resolver_class.complexity || 1
          else
            @complexity || 1
          end
        else
          raise("Invalid complexity: #{new_complexity.inspect} on #{@name}")
        end
      end

      # **Returns**
      #
      # - `Boolean` — True if this field's [max page size](rdoc-ref:#max_page_size) should override the schema default.
      #
      # :call-seq:
      #   has_max_page_size?() -> bool
      def has_max_page_size?
        !NOT_CONFIGURED.equal?(@max_page_size) || (@resolver_class && @resolver_class.has_max_page_size?)
      end

      # **Returns**
      #
      # - `Integer, nil` — Applied to connections if [has max page size?](rdoc-ref:#has_max_page_size?)
      #
      # :call-seq:
      #   max_page_size() -> Integer | nil
      def max_page_size
        if !NOT_CONFIGURED.equal?(@max_page_size)
          @max_page_size
        elsif @resolver_class && @resolver_class.has_max_page_size?
          @resolver_class.max_page_size
        else
          nil
        end
      end

      # **Returns**
      #
      # - `Boolean` — True if this field's [default page size](rdoc-ref:#default_page_size) should override the schema default.
      #
      # :call-seq:
      #   has_default_page_size?() -> bool
      def has_default_page_size?
        !NOT_CONFIGURED.equal?(@default_page_size) || (@resolver_class && @resolver_class.has_default_page_size?)
      end

      # **Returns**
      #
      # - `Integer, nil` — Applied to connections if [has default page size?](rdoc-ref:#has_default_page_size?)
      #
      # :call-seq:
      #   default_page_size() -> Integer | nil
      def default_page_size
        if !NOT_CONFIGURED.equal?(@default_page_size)
          @default_page_size
        elsif @resolver_class && @resolver_class.has_default_page_size?
          @resolver_class.default_page_size
        else
          nil
        end
      end

      def freeze
        type
        owner_type
        arguments_statically_coercible?
        connection?
        super
      end

      class MissingReturnTypeError < GraphQL::Error; end
      attr_writer :type

      # Get or set the return type of this field.
      #
      # It may return nil if no type was configured or if the given definition block wasn't called yet.
      #
      # **Parameters**
      #
      # - `new_type` (`Module, GraphQL::Schema::NonNull, GraphQL::Schema::List`) — A GraphQL return type
      #
      # **Returns**
      #
      # - `Module, GraphQL::Schema::NonNull, GraphQL::Schema::List, nil` — the configured type for this field
      #
      # :call-seq:
      #   type(Module | GraphQL::Schema::NonNull | GraphQL::Schema::List new_type) -> Module | GraphQL::Schema::NonNull | GraphQL::Schema::List | nil
      def type(new_type = NOT_CONFIGURED)
        if NOT_CONFIGURED.equal?(new_type)
          if @resolver_class
            return_type = @return_type_expr || @resolver_class.type_expr
            if return_type.nil?
              raise MissingReturnTypeError, "Can't determine the return type for #{self.path} (it has `resolver: #{@resolver_class}`, perhaps that class is missing a `type ...` declaration, or perhaps its type causes a cyclical loading issue)"
            end
            nullable = @return_type_null.nil? ? @resolver_class.null : @return_type_null
            Member::BuildType.parse_type(return_type, null: nullable)
          elsif !@return_type_expr.nil?
            @type ||= Member::BuildType.parse_type(@return_type_expr, null: @return_type_null)
          end
        else
          @return_type_expr = new_type
          # If `type` is set in the definition block, then the `connection_extension: ...` given as a keyword won't be used, hmm...
          # Also, arguments added by `connection_extension` will clobber anything previously defined,
          # so `type(...)` should go first.
          set_pagination_extensions(connection_extension: self.class.connection_extension)
        end
      rescue GraphQL::Schema::InvalidDocumentError, MissingReturnTypeError => err
        # Let this propagate up
        raise err
      rescue StandardError => err
        raise MissingReturnTypeError, "Failed to build return type for #{@owner.graphql_name}.#{name} from #{@return_type_expr.inspect}: (#{err.class}) #{err.message}", err.backtrace
      end

      def visible?(context)
        if @resolver_class
          @resolver_class.visible?(context)
        else
          true
        end
      end

      def authorizes?(context)
        method(:authorized?).owner != GraphQL::Schema::Field ||
          ((args = context.types.arguments(self)) && (args.any? { |a| a.authorizes?(context) })) ||
          (@resolver_class&.authorizes?(context)) || false
      end

      def authorized?(object, args, context)
        if @resolver_class
          # The resolver _instance_ will check itself during `resolve()`
          @resolver_class.authorized?(object, context)
        else
          if args.size > 0
            if (arg_values = context[:current_arguments])
              # ^^ that's provided by the interpreter at runtime, and includes info about whether the default value was used or not.
              using_arg_values = true
              arg_values = arg_values.argument_values
            else
              arg_values = args
              using_arg_values = false
            end

            args = context.types.arguments(self)
            args.each do |arg|
              arg_key = arg.keyword
              if arg_values.key?(arg_key)
                arg_value = arg_values[arg_key]
                if using_arg_values
                  if arg_value.default_used?
                    # pass -- no auth required for default used
                    next
                  else
                    application_arg_value = arg_value.value
                    if application_arg_value.is_a?(GraphQL::Execution::Interpreter::Arguments)
                      application_arg_value.keyword_arguments
                    end
                  end
                else
                  application_arg_value = arg_value
                end

                if !arg.authorized?(object, application_arg_value, context)
                  return false
                end
              end
            end
          end
          true
        end
      end

      # This method is called by the interpreter for each field.
      # You can extend it in your base field classes.
      #
      # **Parameters**
      #
      # - `object` (`GraphQL::Schema::Object`) — An instance of some type class, wrapping an application object
      # - `args` (`Hash`) — A symbol-keyed hash of Ruby keyword arguments. (Empty if no args)
      # - `ctx` (`GraphQL::Query::Context`)
      #
      # :call-seq:
      #   resolve(GraphQL::Schema::Object object, Hash args, query_ctx)
      def resolve(object, args, query_ctx)
        # Unwrap the GraphQL object to get the application object.
        application_object = object.object
        method_receiver = nil
        method_to_call = nil
        method_args = nil

        @own_validators && Schema::Validator.validate!(validators, application_object, query_ctx, args)

        query_ctx.query.after_lazy(self.authorized?(application_object, args, query_ctx)) do |is_authorized|
          if is_authorized
            with_extensions(object, args, query_ctx) do |obj, ruby_kwargs|
              method_args = ruby_kwargs
              if @resolver_class
                if obj.is_a?(GraphQL::Schema::Object)
                  obj = obj.object
                end
                obj = @resolver_class.new(object: obj, context: query_ctx, field: self)
              end

              inner_object = obj.object

              if !NOT_CONFIGURED.equal?(@hash_key)
                hash_value = if inner_object.is_a?(Hash)
                  inner_object.key?(@hash_key) ? inner_object[@hash_key] : inner_object[@hash_key_str]
                elsif inner_object.respond_to?(:[])
                  inner_object[@hash_key]
                else
                  nil
                end
                if hash_value == false
                  hash_value
                else
                  hash_value || (@fallback_value != NOT_CONFIGURED ? @fallback_value : nil)
                end
              elsif obj.respond_to?(resolver_method)
                method_to_call = resolver_method
                method_receiver = obj
                # Call the method with kwargs, if there are any
                if !ruby_kwargs.empty?
                  obj.public_send(resolver_method, **ruby_kwargs)
                else
                  obj.public_send(resolver_method)
                end
              elsif inner_object.is_a?(Hash)
                if @dig_keys
                  inner_object.dig(*@dig_keys)
                elsif inner_object.key?(@method_sym)
                  inner_object[@method_sym]
                elsif inner_object.key?(@method_str) || !inner_object.default_proc.nil?
                  inner_object[@method_str]
                elsif @fallback_value != NOT_CONFIGURED
                  @fallback_value
                else
                  nil
                end
              elsif inner_object.respond_to?(@method_sym)
                method_to_call = @method_sym
                method_receiver = obj.object
                if !ruby_kwargs.empty?
                  inner_object.public_send(@method_sym, **ruby_kwargs)
                else
                  inner_object.public_send(@method_sym)
                end
              elsif @fallback_value != NOT_CONFIGURED
                @fallback_value
              else
                raise <<-ERR
              Failed to implement #{@owner.graphql_name}.#{@name}, tried:

              - `#{obj.class}##{resolver_method}`, which did not exist
              - `#{inner_object.class}##{@method_sym}`, which did not exist
              - Looking up hash key `#{@method_sym.inspect}` or `#{@method_str.inspect}` on `#{inner_object}`, but it wasn't a Hash

              To implement this field, define one of the methods above (and check for typos), or supply a `fallback_value`.
              ERR
              end
            end
          else
            raise GraphQL::UnauthorizedFieldError.new(object: application_object, type: object.class, context: query_ctx, field: self)
          end
        end
      rescue GraphQL::UnauthorizedFieldError => err
        err.field ||= self
        begin
          query_ctx.schema.unauthorized_field(err)
        rescue GraphQL::ExecutionError => err
          err
        end
      rescue GraphQL::UnauthorizedError => err
        begin
          query_ctx.schema.unauthorized_object(err)
        rescue GraphQL::ExecutionError => err
          err
        end
      rescue ArgumentError
        if method_receiver && method_to_call
          assert_satisfactory_implementation(method_receiver, method_to_call, method_args)
        end
        # if the line above doesn't raise, re-raise
        raise
      rescue GraphQL::ExecutionError => err
        err
      end

      # **Parameters**
      #
      # - `ctx` (`GraphQL::Query::Context`)
      #
      # :call-seq:
      #   fetch_extra(extra_name, GraphQL::Query::Context ctx)
      def fetch_extra(extra_name, ctx)
        if extra_name != :path && extra_name != :ast_node && respond_to?(extra_name)
          self.public_send(extra_name)
        elsif ctx.respond_to?(extra_name)
          ctx.public_send(extra_name)
        else
          raise GraphQL::RequiredImplementationMissingError, "Unknown field extra for #{self.path}: #{extra_name.inspect}"
        end
      end

      private

      def assert_satisfactory_implementation(receiver, method_name, ruby_kwargs)
        method_defn = receiver.method(method_name)
        unsatisfied_ruby_kwargs = ruby_kwargs.dup
        unsatisfied_method_params = []
        encountered_keyrest = false
        method_defn.parameters.each do |(param_type, param_name)|
          case param_type
          when :key
            unsatisfied_ruby_kwargs.delete(param_name)
          when :keyreq
            if unsatisfied_ruby_kwargs.key?(param_name)
              unsatisfied_ruby_kwargs.delete(param_name)
            else
              unsatisfied_method_params << "- `#{param_name}:` is required by Ruby, but not by GraphQL. Consider `#{param_name}: nil` instead, or making this argument required in GraphQL."
            end
          when :keyrest
            encountered_keyrest = true
          when :req
            unsatisfied_method_params << "- `#{param_name}` is required by Ruby, but GraphQL doesn't pass positional arguments. If it's meant to be a GraphQL argument, use `#{param_name}:` instead. Otherwise, remove it."
          when :opt, :rest
            # This is fine, although it will never be present
          end
        end

        if encountered_keyrest
          unsatisfied_ruby_kwargs.clear
        end

        if !unsatisfied_ruby_kwargs.empty? || !unsatisfied_method_params.empty?
          raise FieldImplementationFailed.new, <<-ERR
Failed to call `#{method_name.inspect}` on #{receiver.inspect} because the Ruby method params were incompatible with the GraphQL arguments:

#{ unsatisfied_ruby_kwargs
    .map { |key, value| "- `#{key}: #{value}` was given by GraphQL but not defined in the Ruby method. Add `#{key}:` to the method parameters." }
    .concat(unsatisfied_method_params)
    .join("\n") }
ERR
        end
      end

      class ExtendedState
        def initialize(args, object)
          @arguments = args
          @object = object
          @memos = nil
          @added_extras = nil
        end

        attr_accessor :arguments, :object, :memos, :added_extras
      end

      # Wrap execution with hooks.
      # Written iteratively to avoid big stack traces.
      #
      # **Returns**
      #
      # - `Object` — Whatever the
      #
      # :call-seq:
      #   with_extensions(obj, args, ctx) -> Object
      def with_extensions(obj, args, ctx)
        if @extensions.empty?
          yield(obj, args)
        else
          # This is a hack to get the _last_ value for extended obj and args,
          # in case one of the extensions doesn't `yield`.
          # (There's another implementation that uses multiple-return, but I'm wary of the perf cost of the extra arrays)
          extended = ExtendedState.new(args, obj)
          value = run_extensions_before_resolve(obj, args, ctx, extended) do |obj, args|
            if (added_extras = extended.added_extras)
              args = args.dup
              added_extras.each { |e| args.delete(e) }
            end
            yield(obj, args)
          end

          extended_obj = extended.object
          extended_args = extended.arguments # rubocop:disable Development/ContextIsPassedCop
          memos = extended.memos || EMPTY_HASH

          ctx.query.after_lazy(value) do |resolved_value|
            idx = 0
            @extensions.each do |ext|
              memo = memos[idx]
              # TODO after_lazy?
              resolved_value = ext.after_resolve(object: extended_obj, arguments: extended_args, context: ctx, value: resolved_value, memo: memo)
              idx += 1
            end
            resolved_value
          end
        end
      end

      public

      def run_next_extensions_before_resolve(objs, args, ctx, extended, idx: 0, &block)
        extension = @extensions[idx]
        if extension
          extension.resolve(objects: objs, arguments: args, context: ctx) do |extended_objs, extended_args, memo|
            if memo
              memos = extended.memos ||= {}
              memos[idx] = memo
            end

            if (extras = extension.added_extras)
              ae = extended.added_extras ||= []
              ae.concat(extras)
            end

            extended.object = extended_objs
            extended.arguments = extended_args
            run_next_extensions_before_resolve(extended_objs, extended_args, ctx, extended, idx: idx + 1, &block)
          end
        else
          yield(objs, args)
        end
      end

      private

      def run_extensions_before_resolve(obj, args, ctx, extended, idx: 0)
        extension = @extensions[idx]
        if extension
          extension.resolve(object: obj, arguments: args, context: ctx) do |extended_obj, extended_args, memo|
            if memo
              memos = extended.memos ||= {}
              memos[idx] = memo
            end

            if (extras = extension.added_extras)
              ae = extended.added_extras ||= []
              ae.concat(extras)
            end

            extended.object = extended_obj
            extended.arguments = extended_args
            run_extensions_before_resolve(extended_obj, extended_args, ctx, extended, idx: idx + 1) { |o, a| yield(o, a) }
          end
        else
          yield(obj, args)
        end
      end

      def apply_own_complexity_to(child_complexity, query, nodes)
        case (own_complexity = complexity)
        when Numeric
          own_complexity + child_complexity
        when Proc
          arguments = query.arguments_for(nodes.first, self)
          if arguments.is_a?(GraphQL::ExecutionError)
            return child_complexity
          elsif arguments.respond_to?(:keyword_arguments)
            arguments = arguments.keyword_arguments
          end

          own_complexity.call(query.context, arguments, child_complexity)
        else
          raise ArgumentError, "Invalid complexity for #{self.path}: #{own_complexity.inspect}"
        end
      end

      def set_pagination_extensions(connection_extension:)
        # This should run before connection extension,
        # but should it run after the definition block?
        if scoped?
          self.extension(ScopeExtension, call_after_define: false)
        end

        # The problem with putting this after the definition_block
        # is that it would override arguments
        if connection? && connection_extension
          self.extension(connection_extension, call_after_define: false)
        end
      end
    end
  end
end
