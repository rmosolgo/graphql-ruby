# frozen_string_literal: true
module GraphQL
  module Analysis
    module AST
      class MaxQueryDepth < QueryDepth
        def result
          if @max_depth > query.max_depth
            GraphQL::AnalysisError.new("Query has depth of #{@max_depth}, which exceeds max depth of #{query.max_depth}")
          else
            nil
          end
        end
      end
    end
  end
end
