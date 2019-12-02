# frozen_string_literal: true
module GraphQL
  class Schema
    class Argument
      include GraphQL::Schema::Member::CachedGraphQLDefinition
      include GraphQL::Schema::Member::AcceptsDefinition
      include GraphQL::Schema::Member::HasPath

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
      def initialize(arg_name = nil, type_expr = nil, desc = nil, required:, type: nil, name: nil, loads: nil, description: nil, ast_node: nil, default_value: NO_DEFAULT, as: nil, from_resolver: false, camelize: true, prepare: nil, method_access: true, owner:, &definition_block)
        arg_name ||= name
        name_str = camelize ? Member::BuildType.camelize(arg_name.to_s) : arg_name.to_s
        @name = name_str.freeze
        @type_expr = type_expr || type
        @description = desc || description
        @null = !required
        @default_value = default_value
        @owner = owner
        @as = as
        @loads = loads
        @keyword = as || Schema::Member::BuildType.underscore(@name).to_sym
        @prepare = prepare
        @ast_node = ast_node
        @from_resolver = from_resolver
        @method_access = method_access

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

      def visible?(context)
        true
      end

      def accessible?(context)
        true
      end

      def authorized?(obj, ctx)
        true
      end

      def to_graphql
        argument = GraphQL::Argument.new
        argument.name = @name
        argument.type = -> { type }
        argument.description = @description
        argument.metadata[:type_class] = self
        argument.as = @as
        argument.method_access = @method_access
        if NO_DEFAULT != @default_value
          argument.default_value = @default_value
        end
        argument
      end

      def type
        @type ||= Member::BuildType.parse_type(@type_expr, null: @null)
      rescue StandardError => err
        raise ArgumentError, "Couldn't build type for Argument #{@owner.name}.#{name}: #{err.class.name}: #{err.message}", err.backtrace
      end

      # Apply the {prepare} configuration to `value`, using methods from `obj`.
      # Used by the runtime.
      # @api private
      def prepare_value(obj, value)
        if value.is_a?(GraphQL::Schema::InputObject)
          value = value.prepare
        end

        if @prepare.nil?
          value
        elsif @prepare.is_a?(String) || @prepare.is_a?(Symbol)
          obj.public_send(@prepare, value)
        elsif @prepare.respond_to?(:call)
          @prepare.call(value, obj.context)
        else
          raise "Invalid prepare for #{@owner.name}.name: #{@prepare.inspect}"
        end
      end
    end
  end
end
