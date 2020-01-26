# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      # Wrapper for raw values
      class RawValue
        attr_reader :object

        def initialize(obj = nil)
          @object = obj
        end

        alias_method :resolve, :object
      end

      # Allows to return "raw" value from the resolver
      module HandlesRawValue
        def raw_value(obj = nil)
          RawValue.new(obj)
        end
      end
    end
  end
end
