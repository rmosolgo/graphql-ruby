# frozen_string_literal: true
module GraphQL
  module Analysis
    module AST
      class MaxQueryDepth < QueryDepth
        def result
          max_suported_depth = if multiplex?
            multiplex.schema.max_depth
          else
            query.max_depth
          end

          return if max_suported_depth.nil?

          if @max_depth > max_suported_depth
            GraphQL::AnalysisError.new("Query has depth of #{@max_depth}, which exceeds max depth of #{max_suported_depth}")
          else
            nil
          end
        end
      end
    end
  end
end
