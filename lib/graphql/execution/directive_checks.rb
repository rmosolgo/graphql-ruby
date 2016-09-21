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
        !include?(irep_node, query)
      end

      # @return [Boolean] Should this node be included in the query?
      def include?(irep_node, query)
        irep_node.directives.each do |directive|
          name = directive.name
          return false if name == SKIP && args(directive, query)['if'] == true
          return false if name == INCLUDE && args(directive, query)['if'] == false
        end
        true
      end

      def args(directive_node, query)
        directive_defn = directive_node.definitions.first
        query.arguments_for(directive_node, directive_defn)
      end
    end
  end
end
