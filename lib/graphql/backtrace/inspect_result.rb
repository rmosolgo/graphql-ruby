# frozen_string_literal: true
module GraphQL
  class Backtrace
    module InspectResult
      module_function

      def inspect_result(obj)
        case obj
        when Hash
          "{" +
            obj.map do |key, val|
              "#{key}: #{inspect_truncated(val)}"
            end.join(", ") +
            "}"
        when Array
          "[" +
            obj.map { |v| inspect_truncated(v) }.join(", ") +
            "]"
        else
          inspect_truncated(obj)
        end
      end

      def inspect_truncated(obj)
        case obj
        when Hash
          "{...}"
        when Array
          "[...]"
        when GraphQL::Execution::Lazy
          "(unresolved)"
        else
          "#{obj.inspect}"
        end
      end
    end
  end
end
