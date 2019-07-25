# frozen_string_literal: true
module GraphQL
  module Execution
    # Boolean checks for how an AST node's directives should
    # influence its execution
    # @api private
    module DirectiveChecks
      SKIP = "skip"
      INCLUDE = "include"

      module_function

      # @return [Boolean] Should this node be included in the query?
      def include?(directive_ast_nodes, query)
        directive_ast_nodes.each do |directive_ast_node|
          name = directive_ast_node.name
          directive_defn = query.schema.directives[name]
          case name
          when SKIP
            # TODO This is hard -- we need normalized arguments _now_, but we don't know if it's interpreter or not.
            args = query.arguments_for(directive_ast_node, directive_defn.graphql_definition)
            if args['if'] == true
              return false
            end
          when INCLUDE
            args = query.arguments_for(directive_ast_node, directive_defn.graphql_definition)
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
