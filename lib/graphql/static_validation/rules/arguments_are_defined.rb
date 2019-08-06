# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module ArgumentsAreDefined
      def on_argument(node, parent)
        parent_defn = case parent
        when GraphQL::Language::Nodes::InputObject
          arg_defn = context.argument_definition
          if arg_defn.nil?
            nil
          else
            arg_ret_type = arg_defn.type.unwrap
            if !arg_ret_type.is_a?(GraphQL::InputObjectType)
              nil
            else
              arg_ret_type
            end
          end
        when GraphQL::Language::Nodes::Directive
          context.schema.directives[parent.name]
        when GraphQL::Language::Nodes::Field
          context.field_definition
        else
          raise "Unexpected argument parent: #{parent.class} (##{parent})"
        end

        if parent_defn && context.warden.arguments(parent_defn).any? { |arg| arg.name == node.name }
          super
        elsif parent_defn
          kind_of_node = node_type(parent)
          error_arg_name = parent_name(parent, parent_defn)
          add_error(GraphQL::StaticValidation::ArgumentsAreDefinedError.new(
            "#{kind_of_node} '#{error_arg_name}' doesn't accept argument '#{node.name}'",
            nodes: node,
            name: error_arg_name,
            type: kind_of_node,
            argument: node.name
          ))
        else
          # Some other weird error
          super
        end
      end

      private

      def parent_name(parent, type_defn)
        if parent.is_a?(GraphQL::Language::Nodes::Field)
          parent.alias || parent.name
        elsif parent.is_a?(GraphQL::Language::Nodes::InputObject)
          type_defn.name
        else
          parent.name
        end
      end

      def node_type(parent)
        parent.class.name.split("::").last
      end
    end
  end
end
