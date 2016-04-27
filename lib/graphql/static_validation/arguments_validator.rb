module GraphQL
  module StaticValidation
    # Implement validate_node
    class ArgumentsValidator
      include GraphQL::StaticValidation::Message::MessageHelper

      def validate(context)
        visitor = context.visitor
        visitor[GraphQL::Language::Nodes::Argument] << -> (node, parent) {
          if parent.is_a?(GraphQL::Language::Nodes::InputObject)
            arg_defn = context.argument_definition
            if arg_defn.nil?
              return
            else
              parent_defn = arg_defn.type.unwrap
              if parent_defn.is_a?(GraphQL::ScalarType)
                return
              end
            end
          elsif context.skip_field?(parent.name)
            return
          elsif parent.is_a?(GraphQL::Language::Nodes::Directive)
            parent_defn = context.schema.directives[parent.name]
          else
            parent_defn = context.field_definition
          end
          validate_node(parent, node, parent_defn, context)
        }
      end

      private

      def parent_name(parent, type_defn)
        field_name = if parent.is_a?(GraphQL::Language::Nodes::Field)
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
