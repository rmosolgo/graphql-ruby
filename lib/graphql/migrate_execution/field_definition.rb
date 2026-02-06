# frozen_string_literal: true
module GraphQL
  class MigrateExecution
    class FieldDefinition
      def initialize(type_definition, name, node)
        @type_definition = type_definition
        @name = name.to_sym
        @node = node

        @resolve_mode = NOT_CONFIGURED
        @hash_key = nil
        @resolver = nil
        @type_instance_method = nil
        @object_direct_method = nil

        @resolver_method = nil
        @unknown_options = []
      end

      def migration_strategy
        case resolve_mode
        when NOT_CONFIGURED, nil, :implicit_resolve
          :MANUAL
        when :hash_key, :object_direct_method
          :NONE_REQUIRED
        when :type_instance_method
          @resolver_method.migration_strategy
        when :resolver
          :TODO
        else
          raise "No migration strategy for resolve_mode #{@resolve_mode.inspect}"
        end
      end

      attr_reader :name, :node, :resolver_method, :unknown_options, :type_definition

      attr_writer :resolve_mode

      attr_accessor :hash_key, :object_direct_method, :type_instance_method, :resolver

      def path
        @path ||= "#{type_definition.name}.#{@name}"
      end

      def source_line
        @node.location.start_line
      end

      def resolve_mode
        if NOT_CONFIGURED.equal?(@resolve_mode) || (@resolve_mode == :type_instance_method && @resolver_method.nil?)
          method_name = @type_instance_method || @name
          if (rm = @type_definition.resolver_methods[method_name])
            @resolver_method = rm
            @resolve_mode = :type_instance_method
            @type_instance_method ||= @name
          else
            @resolve_mode = :implicit_resolve
          end
        end
        @resolve_mode
      end

      def implicit_resolve
        @name
      end

      def resolve_mode_key
        resolve_mode && public_send(resolve_mode)
      end
    end
  end
end
