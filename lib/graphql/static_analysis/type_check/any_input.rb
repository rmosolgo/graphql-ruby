module GraphQL
  module StaticAnalysis
    class TypeCheck
      module AnyInput
        ARGUMENTS = {}

        module_function

        def get_argument(name)
          AnyArgument
        end

        def arguments
          ARGUMENTS
        end

        def unwrap
          self
        end

        def kind
          GraphQL::TypeKinds::INPUT_OBJECT
        end
      end
    end
  end
end
