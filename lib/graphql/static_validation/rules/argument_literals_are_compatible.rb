# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module ArgumentLiteralsAreCompatible
      # TODO dedup with ArgumentsAreDefined
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

        if parent_defn && !node.value.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
          arg_defn = parent_defn.arguments[node.name]
          if arg_defn
            begin
              valid = context.valid_literal?(node.value, arg_defn.type)
            rescue GraphQL::CoercionError => err
              error_message = err.message
            end

            if !valid
              error_message ||= begin
                kind_of_node = node_type(parent)
                error_arg_name = parent_name(parent, parent_defn)
                "Argument '#{node.name}' on #{kind_of_node} '#{error_arg_name}' has an invalid value. Expected type '#{arg_defn.type}'."
              end

              add_error(error_message, parent)
            end
          end
        end

        super
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
