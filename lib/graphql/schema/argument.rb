# frozen_string_literal: true
module GraphQL
  class Schema
    class Argument
      if !String.method_defined?(:-@)
        using GraphQL::StringDedupBackport
      end

      include GraphQL::Schema::Member::CachedGraphQLDefinition
      include GraphQL::Schema::Member::AcceptsDefinition
      include GraphQL::Schema::Member::HasPath
      include GraphQL::Schema::Member::HasAstNode

      NO_DEFAULT = :__no_default__

      # @return [String] the GraphQL name for this argument, camelized unless `camelize: false` is provided
      attr_reader :name
      alias :graphql_name :name

      # @return [GraphQL::Schema::Field, Class] The field or input object this argument belongs to
      attr_reader :owner

      # @return [Symbol] A method to call to transform this value before sending it to field resolution method
      attr_reader :prepare

      # @return [Symbol] This argument's name in Ruby keyword arguments
      attr_reader :keyword

      # @return [Class, Module, nil] If this argument should load an application object, this is the type of object to load
      attr_reader :loads

      # @return [Boolean] true if a resolver defined this argument
      def from_resolver?
        @from_resolver
      end

      # @param arg_name [Symbol]
      # @param type_expr
      # @param desc [String]
      # @param required [Boolean] if true, this argument is non-null; if false, this argument is nullable
      # @param description [String]
      # @param default_value [Object]
      # @param as [Symbol] Override the keyword name when passed to a method
      # @param prepare [Symbol] A method to call to transform this argument's valuebefore sending it to field resolution
      # @param camelize [Boolean] if true, the name will be camelized when building the schema
      # @param from_resolver [Boolean] if true, a Resolver class defined this argument
      # @param method_access [Boolean] If false, don't build method access on legacy {Query::Arguments} instances.
      # @param deprecation_reason [String]
      def initialize(arg_name = nil, type_expr = nil, desc = nil, required:, type: nil, name: nil, loads: nil, description: nil, ast_node: nil, default_value: NO_DEFAULT, as: nil, from_resolver: false, camelize: true, prepare: nil, method_access: true, owner:, deprecation_reason: nil, &definition_block)
        arg_name ||= name
        @name = -(camelize ? Member::BuildType.camelize(arg_name.to_s) : arg_name.to_s)
        @type_expr = type_expr || type
        @description = desc || description
        @null = !required
        @default_value = default_value
        @owner = owner
        @as = as
        @loads = loads
        @keyword = as || (arg_name.is_a?(Symbol) ? arg_name : Schema::Member::BuildType.underscore(@name).to_sym)
        @prepare = prepare
        @ast_node = ast_node
        @from_resolver = from_resolver
        @method_access = method_access
        self.deprecation_reason = deprecation_reason

        if definition_block
          if definition_block.arity == 1
            instance_exec(self, &definition_block)
          else
            instance_eval(&definition_block)
          end
        end
      end

      # @return [Object] the value used when the client doesn't provide a value for this argument
      attr_reader :default_value

      # @return [Boolean] True if this argument has a default value
      def default_value?
        @default_value != NO_DEFAULT
      end

      attr_writer :description

      # @return [String] Documentation for this argument
      def description(text = nil)
        if text
          @description = text
        else
          @description
        end
      end

      # @return [String] Deprecation reason for this argument
      def deprecation_reason(text = nil)
        if text
          validate_deprecated_or_optional(null: @null, deprecation_reason: text)
          @deprecation_reason = text
        else
          @deprecation_reason
        end
      end

      alias_method :deprecation_reason=, :deprecation_reason

      def visible?(context)
        true
      end

      def accessible?(context)
        true
      end

      def authorized?(obj, value, ctx)
        authorized_as_type?(obj, value, ctx, as_type: type)
      end

      def authorized_as_type?(obj, value, ctx, as_type:)
        if value.nil?
          return true
        end

        if as_type.kind.non_null?
          as_type = as_type.of_type
        end

        if as_type.kind.list?
          value.each do |v|
            if !authorized_as_type?(obj, v, ctx, as_type: as_type.of_type)
              return false
            end
          end
        elsif as_type.kind.input_object?
          as_type.arguments.each do |_name, input_obj_arg|
            input_obj_arg = input_obj_arg.type_class
            # TODO: this skips input objects whose values were alread replaced with application objects.
            # See: https://github.com/rmosolgo/graphql-ruby/issues/2633
            if value.respond_to?(:key?) && value.key?(input_obj_arg.keyword) && !input_obj_arg.authorized?(obj, value[input_obj_arg.keyword], ctx)
              return false
            end
          end
        end
        # None of the early-return conditions were activated,
        # so this is authorized.
        true
      end

      def to_graphql
        argument = GraphQL::Argument.new
        argument.name = @name
        argument.type = -> { type }
        argument.description = @description
        argument.metadata[:type_class] = self
        argument.as = @as
        argument.ast_node = ast_node
        argument.method_access = @method_access
        if NO_DEFAULT != @default_value
          argument.default_value = @default_value
        end
        if @deprecation_reason
          argument.deprecation_reason = @deprecation_reason
        end
        argument
      end

      def type=(new_type)
        validate_input_type(new_type)
        # This isn't true for LateBoundTypes, but we can assume those will
        # be updated via this codepath later in schema setup.
        if new_type.respond_to?(:non_null?)
          validate_deprecated_or_optional(null: !new_type.non_null?, deprecation_reason: deprecation_reason)
        end
        @type = new_type
      end

      def type
        @type ||= begin
          parsed_type = begin
            Member::BuildType.parse_type(@type_expr, null: @null)
          rescue StandardError => err
            raise ArgumentError, "Couldn't build type for Argument #{@owner.name}.#{name}: #{err.class.name}: #{err.message}", err.backtrace
          end
          # Use the setter method to get validations
          self.type = parsed_type
        end
      end

      def statically_coercible?
        return @statically_coercible if defined?(@statically_coercible)

        @statically_coercible = !@prepare.is_a?(String) && !@prepare.is_a?(Symbol)
      end

      # Apply the {prepare} configuration to `value`, using methods from `obj`.
      # Used by the runtime.
      # @api private
      def prepare_value(obj, value, context: nil)
        if value.is_a?(GraphQL::Schema::InputObject)
          value = value.prepare
        end

        if @prepare.nil?
          value
        elsif @prepare.is_a?(String) || @prepare.is_a?(Symbol)
          if obj.nil?
            # The problem here is, we _used to_ prepare while building variables.
            # But now we don't have the runtime object there.
            #
            # This will have to be called later, when the runtime object _is_ available.
            value
          else
            obj.public_send(@prepare, value)
          end
        elsif @prepare.respond_to?(:call)
          @prepare.call(value, context || obj.context)
        else
          raise "Invalid prepare for #{@owner.name}.name: #{@prepare.inspect}"
        end
      end

      private

      def validate_input_type(input_type)
        if input_type.is_a?(String) || input_type.is_a?(GraphQL::Schema::LateBoundType)
          # Do nothing; assume this will be validated later
        elsif input_type.kind.non_null? || input_type.kind.list?
          validate_input_type(input_type.unwrap)
        elsif !input_type.kind.input?
          raise ArgumentError, "Invalid input type for #{path}: #{input_type.graphql_name}. Must be scalar, enum, or input object, not #{input_type.kind.name}."
        else
          # It's an input type, we're OK
        end
      end

      def validate_deprecated_or_optional(null:, deprecation_reason:)
        if deprecation_reason && !null
          raise ArgumentError, "Required arguments cannot be deprecated: #{path}."
        end
      end
    end
  end
end
