# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module FragmentsAreUsed
      def on_document(node, parent)
        super
        dependency_map = context.dependencies
        dependency_map.unmet_dependencies.each do |op_defn, spreads|
          spreads.each do |fragment_spread|
            add_error("Fragment #{fragment_spread.name} was used, but not defined", fragment_spread.node, path: fragment_spread.path)
          end
        end

        dependency_map.unused_dependencies.each do |fragment|
          if !fragment.name.nil?
            add_error("Fragment #{fragment.name} was defined, but not used", fragment.node, path: fragment.path)
          end
        end
      end
    end
  end
end
