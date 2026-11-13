# frozen_string_literal: true
#--
# typed: true
module GraphQL
  class Query
    class InputValidationResult
      attr_accessor :problems

      def self.from_problem(explanation, path = nil, extensions: nil, message: nil)
        result = self.new
        result.add_problem(explanation, path, extensions: extensions, message: message)
        result
      end

      # Build a valid result which carries the coerced Ruby value for this input.
      #
      # Return this from `validate_non_null_input` to give GraphQL-Ruby the coerced value,
      # so that it doesn't call `coerce_input` again. `value` may be `nil`.
      #
      # **Parameters**
      #
      # - `value` (`Object`) — The coerced Ruby value
      #
      # **Returns**
      #
      # - `GraphQL::Query::InputValidationResult`
      def self.coerced(value)
        result = self.new
        result.coerced_value = value
        result
      end

      def initialize(valid: true, problems: nil)
        @valid = valid
        @problems = problems
        @coerced_value = nil
        @has_coerced_value = false
      end

      # **Returns**
      #
      # - `Object` — The coerced value, if one was given with [coerced_value=](rdoc-ref:#coerced_value=)
      attr_reader :coerced_value

      def coerced_value=(new_value)
        @coerced_value = new_value
        @has_coerced_value = true
      end

      # **Returns**
      #
      # - `Boolean` — true if a coerced value was given with [coerced_value=](rdoc-ref:#coerced_value=)
      def coerced_value?
        @has_coerced_value
      end

      def valid?
        @valid
      end

      def add_problem(explanation, path = nil, extensions: nil, message: nil)
        @problems ||= []
        @valid = false
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
        return if inner_result.nil? || inner_result.valid?

        if inner_result.problems
          inner_result.problems.each do |p|
            item_path = [path, *p["path"]]
            add_problem(p["explanation"], item_path, message: p["message"], extensions: p["extensions"])
          end
        end
        # It could have been explicitly set on inner_result (if it had no problems)
        @valid = false
      end

      VALID = self.new
      VALID.freeze
    end
  end
end
