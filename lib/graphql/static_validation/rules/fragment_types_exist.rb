# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module FragmentTypesExist
      def on_fragment_definition(node, _parent)
        if validate_type_exists(node)
          super
        end
      end

      def on_inline_fragment(node, _parent)
        if validate_type_exists(node)
          super
        end
      end

      private

      def validate_type_exists(fragment_node)
        if !fragment_node.type
          true
        else
          type_name = fragment_node.type.name
          type = context.warden.get_type(type_name)
          if type.nil?
            add_error("No such type #{type_name}, so it can't be a fragment condition", fragment_node)
            false
          else
            true
          end
        end
      end
    end
  end
end
