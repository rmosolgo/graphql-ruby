# frozen_string_literal: true
require_relative "./query_depth"
module GraphQL
  module Analysis
    # Used under the hood to implement depth validation,
    # see {Schema#max_depth} and {Query#max_depth}
    #
    # @example Assert max depth of 10
    #   # DON'T actually do this, graphql-ruby
    #   # Does this for you based on your `max_depth` setting
    #   MySchema.query_analyzers << GraphQL::Analysis::MaxQueryDepth.new(10)
    #
    class MaxQueryDepth < GraphQL::Analysis::QueryDepth
      def initialize(max_depth)
        disallow_excessive_depth = ->(query, depth) {
          if depth > max_depth
            GraphQL::AnalysisError.new("Query has depth of #{depth}, which exceeds max depth of #{max_depth}")
          else
            nil
          end
        }
        super(&disallow_excessive_depth)
      end
    end
  end
end
