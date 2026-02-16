# frozen_string_literal: true
module GraphQL
  class MigrateExecution
    class Visitor < Prism::Visitor
      def initialize(source, type_definitions)
        @source = source
        @type_definitions = type_definitions
        @type_definition_stack = []
        @current_field_definition = nil
        @current_resolver_method = nil
      end

      def visit_class_node(node)
        if node.superclass
          td = @type_definitions[node.name]
          @type_definition_stack << td
        end
        super
      ensure
        if td
          @type_definition_stack.pop
        end
      end

      def visit_module_node(node)
        td = @type_definitions[node.name]
        @type_definition_stack << td
        super
      ensure
        @type_definition_stack.pop
      end

      def visit_keyword_hash_node(node)
        if @current_field_definition
          node.elements.each do |assoc|
            if assoc.key.is_a?(Prism::SymbolNode)
              case assoc.key.unescaped
              when "hash_key"
                @current_field_definition.resolve_mode ||= :hash_key
                @current_field_definition.hash_key = get_keyword_value(assoc.value)
              when "resolver"
                @current_field_definition.resolve_mode ||= :resolver
                @current_field_definition.resolver = get_keyword_value(assoc.value)
              when "method"
                @current_field_definition.resolve_mode ||= :object_direct_method
                @current_field_definition.object_direct_method = get_keyword_value(assoc.value)
              when "resolver_method"
                @current_field_definition.resolve_mode ||= :type_instance_method
                @current_field_definition.type_instance_method = get_keyword_value(assoc.value)
              when "dig"
                @current_field_definition.resolve_mode ||= :dig
                @current_field_definition.dig = get_keyword_value(assoc.value)
              when "resolve_each", "resolve_static", "resolve_batch"
                # These should override any other keywords that are discovered
                @current_field_definition.resolve_mode = :already_migrated
                @current_field_definition.already_migrated = { assoc.key.unescaped.to_sym => get_keyword_value(assoc.value) }
              else
                # fallback_value,  connection, extensions, extras, resolver, mutation, subscription
                @current_field_definition.unknown_options << assoc.key.unescaped
              end
            end
          end
        end
        super
      end

      def visit_call_node(node)
        if node.receiver.nil? && node.name == :field
          first_arg = node.arguments.arguments.first # rubocop:disable Development/ContextIsPassedCop
          if first_arg.is_a?(Prism::SymbolNode)
            field_name = first_arg.unescaped
            td = @type_definition_stack.last
            @current_field_definition = td.field_definition(field_name, node)
          else
            warn "GraphQL-Ruby warning: Skipping unrecognized field definition: #{node.inspect}"
          end
        elsif @current_resolver_method
          if node.receiver.nil? || node.receiver.is_a?(Prism::SelfNode)
            @current_resolver_method.self_sends.add(node.name)
            if node.name == :object
              @current_resolver_method.calls_object = true
            elsif node.name == :context
              @current_resolver_method.calls_context = true
            elsif node.name == :class
              @current_resolver_method.calls_class = true
            end
          end
        end
        super
      ensure
        if td
          @current_field_definition = nil
        end
      end

      def visit_def_node(node)
        if node.receiver.nil?
          td = @type_definition_stack.last
          @current_resolver_method = td.resolver_method(node.name, node)
        end
        super
      ensure
        @current_resolver_method = nil
      end


      private

      def get_keyword_value(value_node)
        case value_node
        when Prism::SymbolNode
          value_node.unescaped.to_sym
        when Prism::StringNode
          value_node.unescaped
        when Prism::IntegerNode, Prism::FloatNode
          value_node.value
        when Prism::TrueNode
          true
        when Prism::FalseNode
          false
        when Prism::ConstantReadNode
          value_node.name.name
        when Prism::ConstantPathNode
          "#{get_keyword_value(value_node.parent)}::#{value_node.name}"
        when Prism::CallNode
          :DYNAMIC_CALL_NODE
        when Prism::ArrayNode
          value_node.elements.map { |n| get_keyword_value(n) }
        else
          # nil, constants, `self` ...?
          raise ArgumentError, "GraphQL-MigrateExecution can't parse this keyword argument yet, but it could. Please open an issue on GraphQL-Ruby with this error message (node class: #{value_node.class})\n\n#{value_node.inspect}"
        end
      end
    end
  end
end
