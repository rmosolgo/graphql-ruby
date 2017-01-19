# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class FragmentsAreFinite
      include GraphQL::StaticValidation::Message::MessageHelper

      def validate(context)
        context.visitor[GraphQL::Language::Nodes::Document].leave << ->(_n, _p) do
          dependency_map = context.dependencies
          dependency_map.cyclical_definitions.each do |defn|
            if defn.node.is_a?(GraphQL::Language::Nodes::FragmentDefinition)
              context.errors << message("Fragment #{defn.name} contains an infinite loop", defn.node, path: defn.path)
            end
          end
        end
      end
    end
  end
end
