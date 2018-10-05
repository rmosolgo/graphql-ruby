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
        def write(path, value, propagating_nil: false)
          write_target = @result
          if write_target
            if path.none?
              @result = value
            else
              path.each_with_index do |path_part, idx|
                next_part = path[idx + 1]
                if next_part.nil?
                  if write_target[path_part].nil? || (propagating_nil)
                    write_target[path_part] = value
                  else
                    raise "Invariant: Duplicate write to #{path} (previous: #{write_target[path_part].inspect}, new: #{value.inspect})"
                  end
                else
                  # Don't have to worry about dead paths here
                  # because it's tracked by the runtime,
                  # and values for dead paths are not sent to this method.
                  write_target = write_target.fetch(path_part, :__unset)
                end
              end
            end
          end
          nil
        end
      end
    end
  end
end
