module GraphQL
  module StaticAnalysis
    class TypeCheck
      module RequiredArguments
        module_function

        def find_errors(parent, argument_owner, node, observed_argument_names)
          # TODO: can we memoize required arguments?
          required_arg_names = argument_owner
            .arguments
            .values
            .select { |arg| arg.type.kind.non_null? }
            .map(&:name)

          errors = []

          # Check for any missing-but-required arguments
          if required_arg_names.any?
            missing_arg_names = required_arg_names - observed_argument_names
            if missing_arg_names.any?

              case parent
              when GraphQL::BaseType
                owner_name = "#{parent.name}.#{argument_owner.name}"
              else
                owner_name = "#{argument_owner.name}"
              end

              errors << AnalysisError.new(
                %|Required arguments missing from "#{owner_name}": "#{missing_arg_names.join('", "')}"|,
                nodes: [node],
              )
            end
          end

          errors
        end
      end
    end
  end
end
