# frozen_string_literal: true
module GraphQL
  module Analysis
    # A query reducer for measuring the depth of a given query.
    #
    # @example Logging the depth of a query
    #   Schema.query_analyzers << GraphQL::Analysis::QueryDepth.new { |query, depth|  puts "GraphQL query depth: #{depth}" }
    #   Schema.execute(query_str)
    #   # GraphQL query depth: 8
    #
    class QueryDepth
      def initialize(&block)
        @depth_handler = block
      end

      def initial_value(query)
        {
          max_depth: 0,
          current_depth: 0,
          query: query,
        }
      end

      def call(memo, visit_type, irep_node)
        if irep_node.ast_node.is_a?(GraphQL::Language::Nodes::Field)
          if visit_type == :enter
            memo[:current_depth] += 1
          else
            if memo[:max_depth] < memo[:current_depth]
              memo[:max_depth] = memo[:current_depth]
            end
            memo[:current_depth] -= 1
          end
        end
        memo
      end

      def final_value(memo)
        @depth_handler.call(memo[:query], memo[:max_depth])
      end
    end
  end
end
