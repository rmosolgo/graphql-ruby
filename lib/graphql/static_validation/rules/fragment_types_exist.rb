# frozen_string_literal: true
# typed: strict
module GraphQL
  module StaticValidation
    #--
    # @requires_ancestor: GraphQL::StaticValidation::BaseVisitor
    module FragmentTypesExist
      #: (GraphQL::Language::Nodes::FragmentDefinition node, GraphQL::Language::Nodes::AbstractNode? _parent) -> void
      def on_fragment_definition(node, _parent)
        if validate_type_exists(node)
          super
        end
      end

      #: (GraphQL::Language::Nodes::InlineFragment node, GraphQL::Language::Nodes::AbstractNode? _parent) -> void
      def on_inline_fragment(node, _parent)
        if validate_type_exists(node)
          super
        end
      end

      private

      #: (GraphQL::Language::Nodes::FragmentDefinition | GraphQL::Language::Nodes::InlineFragment fragment_node) -> bool
      def validate_type_exists(fragment_node)
        if !fragment_node.type
          true
        else
          fragment_type = fragment_node.type #: as !nil
          type_name = fragment_type.name
          type = types.type(type_name)
          if type.nil?
            suggestion = if schema.did_you_mean
              @all_possible_fragment_type_names ||= begin
                names = [] #: Array[String]
                context.types.all_types.each do |type|
                  if type.kind.fields?
                    names << type.graphql_name
                  end
                end
                names
              end #: Array[String]?
              context.did_you_mean_suggestion(type_name, @all_possible_fragment_type_names)
            end

            add_error(GraphQL::StaticValidation::FragmentTypesExistError.new(
              "No such type #{type_name}, so it can't be a fragment condition#{suggestion}",
              nodes: fragment_node,
              type: type_name
            ))
            false
          else
            true
          end
        end
      end
    end
  end
end
