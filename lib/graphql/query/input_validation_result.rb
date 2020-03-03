# frozen_string_literal: true
module GraphQL
  class Query
    class InputValidationResult
      attr_accessor :problems
      attr_reader :extensions, :message

      def valid?
        @problems.nil?
      end

      def add_problem(explanation, path = nil, extensions: nil, message: nil)
        @problems ||= []
        problem = { "path" => path || [], "explanation" => explanation }
        if extensions
          problem["extensions"] = extensions
        end
        if message
          problem["message"] = message
        end
        @problems.push(problem)
      end

      def merge_result!(path, inner_result)
        return if inner_result.valid?

        inner_result.problems.each do |p|
          item_path = [path, *p["path"]]
          add_problem(p["explanation"], item_path, message: p["message"], extensions: p["extensions"])
        end
      end
    end
  end
end
