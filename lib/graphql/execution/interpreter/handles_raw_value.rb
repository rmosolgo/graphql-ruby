# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      # Wrapper for raw values
      class RawValue
        def initialize(obj = nil)
          @object = obj
        end

        def resolve
          @object
        end
      end

      # Allows to return "raw" value from the resolver
      module HandlesRawValue
        def raw_value(obj)
          RawValue.new(obj)
        end
      end
    end
  end
end
