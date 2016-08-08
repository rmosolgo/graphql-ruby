module GraphQL
  module Execution
    # Boolean checks for how an AST node's directives should
    # influence its execution
    module DirectiveChecks
      SKIP = "skip"
      INCLUDE = "include"

      module_function

      # This covers `@include(if:)` & `@skip(if:)`
      # @return [Boolean] Should this node be skipped altogether?
      def skip?(irep_node, query)
        irep_node.directives.each do |directive_node|
          if directive_node.name == SKIP || directive_node.name == INCLUDE
            directive_defn = directive_node.definitions.first
            args = query.arguments_for(directive_node, directive_defn)
            if !directive_defn.include?(args)
              return true
            end
          end
        end
        false
      end

      # @return [Boolean] Should this node be included in the query?
      def include?(irep_node, query)
        !skip?(irep_node, query)
      end
    end
  end
end
