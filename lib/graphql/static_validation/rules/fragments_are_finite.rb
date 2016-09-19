module GraphQL
  module StaticValidation
    class FragmentsAreFinite
      include GraphQL::StaticValidation::Message::MessageHelper

      def validate(context)
        context.visitor[GraphQL::Language::Nodes::FragmentDefinition] << -> (node, parent) {
          if has_nested_spread(node, [], context)
            context.errors << message("Fragment #{node.name} contains an infinite loop", node, context: context)
          end
        }
      end

      private

      def has_nested_spread(fragment_def, parent_fragment_names, context)
        nested_spreads = get_spreads(fragment_def.selections)

        nested_spreads.any? do |spread|
          nested_def = context.fragments[spread.name]
          parent_fragment_names.include?(spread.name) || has_nested_spread(nested_def, parent_fragment_names + [fragment_def.name], context)
        end
      end

      # Find spreads contained in this selection & return them in a flat array
      def get_spreads(selection)
        case selection
        when GraphQL::Language::Nodes::FragmentSpread
          [selection]
        when GraphQL::Language::Nodes::Field, GraphQL::Language::Nodes::InlineFragment
          get_spreads(selection.selections)
        when Array
          selection.map { |s| get_spreads(s) }.flatten
        end
      end
    end
  end
end
