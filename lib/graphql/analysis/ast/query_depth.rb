# frozen_string_literal: true
module GraphQL
  module Analysis
    # A query reducer for measuring the depth of a given query.
    #
    # See https://graphql-ruby.org/queries/ast_analysis.html for more examples.
    #
    # @example Logging the depth of a query
    #   class LogQueryDepth < GraphQL::Analysis::QueryDepth
    #     def result
    #       log("GraphQL query depth: #{@max_depth}")
    #     end
    #   end
    #
    #   # In your Schema file:
    #
    #   class MySchema < GraphQL::Schema
    #     use GraphQL::Analysis::AST
    #     query_analyzer LogQueryDepth
    #   end
    #
    #   # When you run the query, the depth will get logged:
    #
    #   Schema.execute(query_str)
    #   # GraphQL query depth: 8
    #
    module AST
      class QueryDepth < Analyzer
        def initialize(query)
          @max_depth = 0
          @current_depth = 0
          super
        end

        def on_enter_field(node, parent, visitor)
          return if visitor.skipping? || visitor.visiting_fragment_definition?

          @current_depth += 1
        end

        def on_leave_field(node, parent, visitor)
          return if visitor.skipping? || visitor.visiting_fragment_definition?

          if @max_depth < @current_depth
            @max_depth = @current_depth
          end
          @current_depth -= 1
        end

        def result
          @max_depth
        end
      end
    end
  end
end
