# frozen_string_literal: true
module GraphQL
  class Query
    class InputValidationResult
      attr_accessor :problems

      def initialize(schema)
        @schema = schema
        @problems = []
      end

      def valid?
        @problems.empty?
      end

      def too_many_errors?
        @problems.size >= @schema.max_validation_errors
      end

      def add_problem(explanation, path = nil)
        @problems.push({ "path" => path || [], "explanation" => explanation })
      end

      def merge_result!(path, inner_result)
        return if inner_result.valid?

        inner_result.problems.each do |p|
          item_path = [path, *p["path"]]
          add_problem(p["explanation"], item_path)
          break if too_many_errors?
        end
      end
    end
  end
end
