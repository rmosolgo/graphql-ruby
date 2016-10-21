module GraphQL
  module StaticAnalysis
    class TypeCheck
      # This object can replace a field definition,
      # it says yes to any argument and it returns any type.
      module AnyField
        ARGUMENTS = {}

        module_function

        def type
          AnyType
        end

        def arguments
          ARGUMENTS
        end

        def get_argument(name)
          AnyArgument
        end
      end
    end
  end
end
