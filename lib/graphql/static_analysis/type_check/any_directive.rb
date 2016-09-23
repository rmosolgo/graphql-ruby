module GraphQL
  module StaticAnalysis
    class TypeCheck
      module AnyDirective
        ARGUMENTS = {}

        module_function

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
