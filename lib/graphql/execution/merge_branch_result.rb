module GraphQL
  module Execution
    module MergeBranchResult
      # Modify `complete_result` by recursively merging `type_branch_result`
      # @return [void]
      def self.merge(complete_result, type_branch_result)
        type_branch_result.each do |key, branch_value|
          prev_value = complete_result[key]
          case prev_value
          when nil
            complete_result[key] = branch_value
          when Hash
            merge(prev_value, branch_value)
          else
            # Sad, this was not needed.
          end
        end
      end
    end
  end
end
