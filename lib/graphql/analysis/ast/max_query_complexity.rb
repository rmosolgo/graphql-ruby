# frozen_string_literal: true
require_relative "./query_complexity"
module GraphQL
  module Analysis
    module AST
      # Used under the hood to implement complexity validation,
      # see {Schema#max_complexity} and {Query#max_complexity}
      class MaxQueryComplexity < QueryComplexity
        def result
          max_complexity = if multiplex?
            multiplex.max_complexity
          else
            query.max_complexity
          end

          return if max_complexity.nil?

          total_complexity = max_possible_complexity

          if total_complexity > max_complexity
            GraphQL::AnalysisError.new("Query has complexity of #{total_complexity}, which exceeds max complexity of #{max_complexity}")
          else
            nil
          end
        end
      end
    end
  end
end
