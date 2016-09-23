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
      def skip?(ast_node, query)
        !include?(ast_node, query)
      end

      # @return [Boolean] Should this node be included in the query?
      def include?(directive_irep_nodes, query)
        directive_irep_nodes.each do |directive_irep_node|
          name = directive_irep_node.name
          directive_defn = query.schema.directives[name]
          case name
          when SKIP
            args = query.arguments_for(directive_irep_node, directive_defn)
            if args['if'] == true
              return false
            end
          when INCLUDE
            args = query.arguments_for(directive_irep_node, directive_defn)
            if args['if'] == false
              return false
            end
          else
            # Undefined directive, or one we don't care about
          end
        end
        true
      end
    end
  end
end
