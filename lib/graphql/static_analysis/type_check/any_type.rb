module GraphQL
  module StaticAnalysis
    class TypeCheck
      # This object behaves like an instance of {GraphQL::BaseType}
      # _except_ it has magical properties:
      #
      # - It has fields with _any_ name, instances of {GraphQL::StaticAnalysis::TypeCheck::AnyField}
      # - Or, it can be a scalar ({AnyType} don't care, it's typekind is {AnyKind})
      # - In abstract scope, it has types in common with _any_ other scope
      #
      # This supports error handling in type-checking:
      # when we lose type information, we insert {AnyType}
      # (until we can regain some info, eg fragment types)
      module AnyType
        module_function

        def unwrap
          self
        end

        def get_field(name)
          AnyField
        end

        def kind
          AnyTypeKind
        end

        def to_non_null_type
          self
        end

        def to_list_type
          self
        end
      end
    end
  end
end
