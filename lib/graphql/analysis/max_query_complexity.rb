# frozen_string_literal: true
require_relative "./query_complexity"
module GraphQL
  module Analysis
    # Used under the hood to implement complexity validation,
    # see {Schema#max_complexity} and {Query#max_complexity}
    #
    # @example Assert max complexity of 10
    #   # DON'T actually do this, graphql-ruby
    #   # Does this for you based on your `max_complexity` setting
    #   MySchema.query_analyzers << GraphQL::Analysis::MaxQueryComplexity.new(10)
    #
    class MaxQueryComplexity < GraphQL::Analysis::QueryComplexity
      def initialize(max_complexity)
        disallow_excessive_complexity = ->(query, complexity) {
          if complexity > max_complexity
            GraphQL::AnalysisError.new("Query has complexity of #{complexity}, which exceeds max complexity of #{max_complexity}")
          else
            nil
          end
        }
        super(&disallow_excessive_complexity)
      end
    end
  end
end
