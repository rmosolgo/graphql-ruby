module GraphQL
  module StaticAnalysis
    class TypeCheck
      # This object quacks like an argument -- except it always says "yes"!
      # Use it when a proper argument definition can't be found.
      module AnyArgument
        module_function
        def type
          AnyInput
        end
      end
    end
  end
end
