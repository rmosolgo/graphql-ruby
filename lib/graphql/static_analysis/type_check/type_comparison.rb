module GraphQL
  module StaticAnalysis
    class TypeCheck
      module TypeComparison
        NO_ERROR = 0
        INVALID_DEFINITION = 1
        TYPE_MISMATCH = 2
        NULLABILITY_MISMATCH = 3
        LIST_MISMATCH = 4

        module_function

        # Check if `left_type` accepts `right_type` as an input.
        # @return [NO_ERROR, INVALID_DEFINITION, TYPE_MISMATCH, NULLABILITY_MISMATCH, LIST_MISMATCH]
        def compare_inputs(left_type, right_type, has_default:)
          right_inner_type = right_type.unwrap

          if right_inner_type == AnyType || !right_inner_type.kind.input?
            # This is an invalid definition, handled in the definition validation
            return INVALID_DEFINITION
          end

          # If it has a default value, give it a "bonus" non-null wrapper
          # since it can be used in places where a value is required
          if has_default
            right_type = GraphQL::NonNullType.new(of_type: right_type)
          end

          left_inner_type = left_type.unwrap

          if left_inner_type != right_inner_type
            TYPE_MISMATCH
          elsif list_dimension(left_type) != list_dimension(right_type)
            LIST_MISMATCH
          elsif !non_null_levels_match?(left_type, right_type)
            NULLABILITY_MISMATCH
          else
            NO_ERROR
          end
        end

        private

        module_function
        # For example, `list_dimension([[Int]]) => 2 `
        # @param type [GraphQL::BaseType] maybe a list type ... maybe a nested list type
        # @return [Integer] how many layers of lists there are
        def list_dimension(type)
          if type.kind.list?
            1 + list_dimension(type.of_type)
          elsif type.kind.non_null?
            list_dimension(type.of_type)
          else
            0
          end
        end

        def non_null_levels_match?(arg_type, var_type)
          if arg_type.kind.non_null? && !var_type.kind.non_null?
            false
          elsif arg_type.kind.wraps? && var_type.kind.wraps?
            # If var_type is a non-null wrapper for a type, and arg_type is nullable, peel off the wrapper
            # That way, a var_type of `[DairyAnimal]!` works with an arg_type of `[DairyAnimal]`
            if var_type.kind.non_null? && !arg_type.kind.non_null?
              var_type = var_type.of_type
            end
            non_null_levels_match?(arg_type.of_type, var_type.of_type)
          else
            true
          end
        end
      end
    end
  end
end
