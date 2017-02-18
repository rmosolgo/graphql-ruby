# frozen_string_literal: true
module GraphQL
  class Directive
    # For each visited node, check if its directives make it skipped.
    #
    # If it _is_ skipped, don't yield it to be rewritten.
    # Instead, register it in the skipped set.
    # Then, on the way _out_, if the node is in the skipped set, remove it.
    #
    # If it's not in the skipped set, yield to rewrite so that it can run its exit hooks.
    #
    class SkipInterceptor
      def initialize(query)
        @query = query
        @skipped = Set.new
      end

      def enter(ast_node)
        if skip?(ast_node)
          @skipped.add(ast_node)
        elsif @skipped.none?
          yield
        end
      end

      def leave(ast_node)
        if @skipped.none?
          yield
        else
          # Maybe this is a miss, who cares
          @skipped.delete(ast_node)
        end
      end

      private

      def skip?(ast_node)
        dir_nodes = ast_node.directives

        dir_nodes.any? && dir_nodes.each do |dir_node|
          name = dir_node.name
          case name
          when "skip"
            directive_defn = @query.schema.directives[name]
            args = @query.arguments_for(dir_node, directive_defn)
            if args['if'] == true
              return true
            end
          when "include"
            directive_defn = @query.schema.directives[name]
            args = @query.arguments_for(dir_node, directive_defn)
            if args['if'] == false
              return true
            end
          else
            # Undefined directive, or one we don't care about
          end
        end

        false
      end
    end
  end
end
