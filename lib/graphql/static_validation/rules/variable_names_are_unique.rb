# frozen_string_literal: true
# typed: true
module GraphQL
  module StaticValidation
    #--
    # @requires_ancestor: GraphQL::StaticValidation::BaseVisitor
    module VariableNamesAreUnique
      def on_operation_definition(node, parent)
        var_defns = node.variables
        if !var_defns.empty?
          vars_by_name = Hash.new { |h, k| h[k] = [] }
          var_defns.each { |v| vars_by_name[v.name] << v }
          vars_by_name.each do |name, defns|
            if defns.size > 1
              add_error(GraphQL::StaticValidation::VariableNamesAreUniqueError.new(
                "There can only be one variable named \"#{name}\"",
                nodes: defns,
                name: name
              ))
            end
          end
        end
        super
      end
    end
  end
end
