module GraphQL
  module StaticAnalysis
    class TypeCheck
      module AnyInput
        module_function

        def get_argument(name)
          AnyArgument
        end

        def unwrap
          self
        end
      end
    end
  end
end
