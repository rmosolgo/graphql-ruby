# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class FragmentsAreUsed
      include GraphQL::StaticValidation::Message::MessageHelper

      def validate(context)
        context.visitor[GraphQL::Language::Nodes::Document].leave << ->(_n, _p) do
          dependency_map = context.dependencies
          dependency_map.unmet_dependencies.each do |op_defn, spreads|
            spreads.each do |fragment_spread|
              context.errors << message("Fragment #{fragment_spread.name} was used, but not defined", fragment_spread.node, path: fragment_spread.path)
            end
          end

          dependency_map.unused_dependencies.each do |fragment|
            if !fragment.name.nil?
              context.errors << message("Fragment #{fragment.name} was defined, but not used", fragment.node, path: fragment.path)
            end
          end
        end
      end
    end
  end
end
