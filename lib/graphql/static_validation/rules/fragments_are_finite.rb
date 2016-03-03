module GraphQL
  module StaticValidation
    class FragmentsAreFinite
      include GraphQL::StaticValidation::Message::MessageHelper

      def validate(context)
        context.visitor[GraphQL::Language::Nodes::FragmentDefinition] << -> (node, parent) {
          if has_nested_spread(node, [], context)
            context.errors << message("Fragment #{node.name} contains an infinite loop", node)
          end
        }
      end

      private

      def has_nested_spread(fragment_def, parent_fragment_names, context)
        nested_spreads = fragment_def.selections
          .select {|f| f.is_a?(GraphQL::Language::Nodes::FragmentSpread)}

        nested_spreads.any? do |spread|
          nested_def = context.fragments[spread.name]
          parent_fragment_names.include?(spread.name) || has_nested_spread(nested_def, parent_fragment_names + [fragment_def.name], context)
        end
      end
    end
  end
end
