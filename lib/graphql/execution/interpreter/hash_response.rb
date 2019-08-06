# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      # This response class handles `#write` by accumulating
      # values into a Hash.
      class HashResponse
        def initialize
          @result = {}
        end

        def final_value
          @result
        end

        def inspect
          "#<#{self.class.name} result=#{@result.inspect}>"
        end

        # Add `value` at `path`.
        # @return [void]
        def write(path, value)
          if path.empty?
            @result = value
          elsif (write_target = @result)
            i = 0
            prefinal_steps = path.size - 1
            # Use `while` to avoid a closure
            while i < prefinal_steps
              path_part = path[i]
              i += 1
              write_target = write_target[path_part]
            end
            path_part = path[i]
            write_target[path_part] = value
          else
            # The response is completely nulled out
          end

          nil
        end
      end
    end
  end
end
