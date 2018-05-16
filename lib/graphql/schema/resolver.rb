# frozen_string_literal: true

module GraphQL
  class Schema
    class Resolver
      include Schema::Member::GraphQLTypeNames
      # Really we only need description from here, but:
      extend Schema::Member::BaseDSLMethods
      extend GraphQL::Schema::Member::HasArguments
      extend Schema::Member::GeneratesField

      # @param object [Object] the initialize object, pass to {Query.initialize} as `root_value`
      # @param context [GraphQL::Query::Context]
      def initialize(object:, context:)
        @object = object
        @context = context
      end

      # @return [Object] The application object this field is being resolved on
      attr_reader :object

      # @return [GraphQL::Query::Context]
      attr_reader :context

      # Do the work. Everything happens here.
      # @return [Object] An object corresponding to the return type
      def resolve(**args)
        raise NotImplementedError, "#{self.class.name}#resolve should execute the field's logic"
      end

      class << self
        def field_class(new_class = nil)
          if new_class
            @field_class = new_class
          else
            @field_class || find_inherited_method(:field_class, GraphQL::Schema::Field)
          end
        end

        # Default `:resolve` set below.
        # @return [Symbol] The method to call on instances of this object to resolve the field
        def resolve_method(new_method = nil)
          if new_method
            @resolve_method = new_method
          end
          @resolve_method || (superclass.respond_to?(:resolve_method) ? superclass.resolve_method : :resolve)
        end

        # Additional info injected into {#resolve}
        # @see {GraphQL::Schema::Field#extras}
        def extras(new_extras = nil)
          if new_extras
            @extras = new_extras
          end
          @extras || []
        end

        # This name will be used for the {.field}.
        def field_name
          graphql_name.sub(/^[A-Z]/, &:downcase)
        end

        # An object class to use for deriving return types
        # @param new_class [Class, nil] Defaults to {GraphQL::Schema::Object}
        # @return [Class]
        def object_class(new_class = nil)
          if new_class
            @object_class = new_class
          end
          @object_class || (superclass.respond_to?(:object_class) ? superclass.object_class : GraphQL::Schema::Object)
        end

        # Specifies whether or not the field is nullable. Defaults to `true`
        # TODO unify with {#type}
        # @param allow_null [Boolean] Whether or not the response can be null
        def null(allow_null = nil)
          if !allow_null.nil?
            @null = allow_null
          end

          @null.nil? ? (superclass.respond_to?(:null) ? superclass.null : true) : @null
        end

        # Call this method to get the return type of the field,
        # or use it as a configuration method to assign a return type
        # instead of generating one.
        # TODO unify with {#null}
        # @param new_type [Class, nil] If a type definition class is provided, it will be used as the return type of the field
        # @param null [true, false] Whether or not the field may return `nil`
        # @return [Class] The type which this field returns.
        def type(new_type = nil, null: nil)
          if new_type
            if null.nil?
              raise ArgumentError, "required argument `null:` is missing"
            end
            @type_expr = new_type
            @null = null
          else
            if @type_expr
              GraphQL::Schema::Member::BuildType.parse_type(@type_expr, null: @null)
            elsif superclass.respond_to?(:type)
              superclass.type
            else
              nil
            end
          end
        end

        def field_options
          super.merge({
            name: field_name,
            type: type_expr,
            description: description,
            extras: extras,
            method: resolve_method,
            resolver_class: self,
            arguments: arguments,
            null: null,
          })
        end

        # A non-normalized type configuration, without `null` applied
        # @api private
        def type_expr
          @type_expr || (superclass.respond_to?(:type_expr) ? superclass.type_expr : nil)
        end
      end
    end
  end
end
