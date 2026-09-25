# frozen_string_literal: true
module GraphQL
  class Schema
    # Extend this class to make field-level customizations to resolve behavior.
    #
    # When a extension is added to a field with `extension(MyExtension)`, a `MyExtension` instance
    # is created, and its hooks are applied whenever that field is called.
    #
    # The instance is frozen so that instance variables aren't modified during query execution,
    # which could cause all kinds of issues due to race conditions.
    class FieldExtension
      # **Returns**
      #
      # - `GraphQL::Schema::Field`
      attr_reader :field

      # **Returns**
      #
      # - `Object`
      attr_reader :options

      # **Returns**
      #
      # - `Array<Symbol>, nil` — `default_argument`s added, if any were added (otherwise, `nil`)
      attr_reader :added_default_arguments

      # Called when the extension is mounted with `extension(name, options)`.
      # The instance will be frozen to avoid improper use of state during execution.
      #
      # **Parameters**
      #
      # - `field` (`GraphQL::Schema::Field`) — The field where this extension was mounted
      # - `options` (`Object`) — The second argument to `extension`, or `{}` if nothing was passed.
      #
      # :call-seq:
      #   initialize(GraphQL::Schema::Field field:, Object options:)
      def initialize(field:, options:)
        @field = field
        @options = options || {}
        @added_default_arguments = nil
        apply
      end

      class << self
        # **Returns**
        #
        # - `Array(Array, Hash), nil` — A list of default argument configs, or `nil` if there aren't any
        #
        # :call-seq:
        #   default_argument_configurations() -> Array(Array, Hash) | nil
        def default_argument_configurations
          args = superclass.respond_to?(:default_argument_configurations) ? superclass.default_argument_configurations : nil
          if @own_default_argument_configurations
            if args
              args.concat(@own_default_argument_configurations)
            else
              args = @own_default_argument_configurations.dup
            end
          end
          args
        end

        # See the [GraphQL::Schema::Argument](rdoc-ref:GraphQL::Schema::Argument) API.
        # See [HasArguments#argument](rdoc-ref:GraphQL::Schema::Member::HasArguments#argument) for argument configuration.
        def default_argument(*argument_args, **argument_kwargs)
          configs = @own_default_argument_configurations ||= []
          configs << [argument_args, argument_kwargs]
        end

        # If configured, these `extras` will be added to the field if they aren't already present,
        # but removed by from `arguments` before the field's `resolve` is called.
        # (The extras _will_ be present for other extensions, though.)
        #
        # **Parameters**
        #
        # - `new_extras` (`Array<Symbol>`) — If provided, assign extras used by this extension
        #
        # **Returns**
        #
        # - `Array<Symbol>` — any extras assigned to this extension
        #
        # :call-seq:
        #   extras(Array[Symbol] new_extras) -> Array[Symbol]
        def extras(new_extras = nil)
          if new_extras
            @own_extras = new_extras
          end

          inherited_extras = self.superclass.respond_to?(:extras) ? superclass.extras : nil
          if @own_extras
            if inherited_extras
              inherited_extras + @own_extras
            else
              @own_extras
            end
          elsif inherited_extras
            inherited_extras
          else
            GraphQL::EmptyObjects::EMPTY_ARRAY
          end
        end
      end

      # Called when this extension is attached to a field.
      # The field definition may be extended during this method.
      #
      # **Returns**
      #
      # - `void`
      #
      # :call-seq:
      #   apply() -> void
      def apply
      end

      # Called after the field's definition block has been executed.
      # (Any arguments from the block are present on `field`)
      #
      # **Returns**
      #
      # - `void`
      #
      # :call-seq:
      #   after_define() -> void
      def after_define
      end

      def after_define_apply # :nodoc:
        after_define
        if (configs = self.class.default_argument_configurations)
          existing_keywords = field.all_argument_definitions.map(&:keyword)
          existing_keywords.uniq!
          @added_default_arguments = []
          configs.each do |config|
            argument_args, argument_kwargs = config
            arg_name = argument_args[0]
            if !existing_keywords.include?(arg_name)
              @added_default_arguments << arg_name
              field.argument(*argument_args, **argument_kwargs)
            end
          end
        end
        if !(extras = self.class.extras).empty?
          @added_extras = extras - field.extras
          field.extras(@added_extras)
        else
          @added_extras = nil
        end
        freeze
      end

      attr_reader :added_extras # :nodoc:

      # Called before resolving [field](rdoc-ref:#field). It should either:
      #
      # - `yield` values to continue execution; OR
      # - return something else to shortcut field execution.
      #
      # Whatever this method returns will be used for execution.
      #
      # **Parameters**
      #
      # - `object` (`Object`) — The object the field is being resolved on (not passed by new execution)
      # - `objects` (`Array<Object>`) — The objects the field is being resolved on (passed by new execution)
      # - `arguments` (`Hash`) — Ruby keyword arguments for resolving this field
      # - `context` (`Query::Context`) — the context for this query
      #
      # **Yields**
      #
      # - `object_or_objects` (`Object, Array<Object>`) — The object or objects (new execution) to continue resolving the field on
      # - `arguments` (`Hash`) — The keyword arguments to continue resolving with
      # - `memo` (`Object`) — Any extension-specific value which will be passed to [after resolve](rdoc-ref:#after_resolve) later
      #
      # **Returns**
      #
      # - `Object` — The return value for this field.
      #
      # :call-seq:
      #   resolve(Object object:, Array[Object] objects:, Hash arguments:, Query::Context context:) -> Object
      def resolve(object: nil, objects: nil, arguments:, context:)
        yield(object.nil? ? objects : object, arguments, nil)
      end

      # Called after [field](rdoc-ref:#field) was resolved, and after any lazy values (like `Promise`s) were synced,
      # but before the value was added to the GraphQL response.
      #
      # Whatever this hook returns will be used as the return value.
      #
      # **Parameters**
      #
      # - `object` (`Object`) — The object the field is being resolved on (not passed by new execution)
      # - `objects` (`Array<Object>`) — The object the field is being resolved on (passed by new execution)
      # - `arguments` (`Hash`) — Ruby keyword arguments for resolving this field
      # - `context` (`Query::Context`) — the context for this query
      # - `value` (`Object`) — Whatever the field previously returned (not passed by new execution)
      # - `values` (`Array<Object>`) — Whatever the field previously returned (passed by new execution)
      # - `memo` (`Object`) — The third value yielded by [resolve](rdoc-ref:#resolve), or `nil` if there wasn't one
      #
      # **Returns**
      #
      # - `Object` — The return value for this field.
      #
      # :call-seq:
      #   after_resolve(Object object:, Array[Object] objects:, Hash arguments:, Query::Context context:, Array[Object] values:, Object value:, Object memo:) -> Object
      def after_resolve(object: nil, objects: nil, arguments:, context:, values: nil, value: nil, memo:)
        value.nil? ? values : value
      end
    end
  end
end
