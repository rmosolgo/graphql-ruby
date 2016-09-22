module GraphQL
  module StaticAnalysis
    class TypeCheck
      module AnyTypeKind
        module_function

        def fields?; true; end
        def composite?; true; end
        def scalar?; true; end
      end
    end
  end
end
