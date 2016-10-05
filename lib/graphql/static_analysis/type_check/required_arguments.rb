module GraphQL
  module StaticAnalysis
    class TypeCheck
      module RequiredArguments
        module_function

        def find_error(parent, argument_owner, node, observed_argument_names)
          # TODO: can we memoize required arguments?
          required_arg_names = argument_owner
            .arguments
            .values
            .select { |arg| arg.type.kind.non_null? }
            .map(&:name)

          # Check for any missing-but-required arguments
          if required_arg_names.any?
            missing_arg_names = required_arg_names - observed_argument_names
            if missing_arg_names.any?

              owner_name = case argument_owner
              when GraphQL::Field
                "#{parent.name}.#{argument_owner.name}"
              when GraphQL::Directive
                "@#{argument_owner.name}"
              else GraphQL::Argument
                argument_owner.name
              end

              return %|Required arguments missing from "#{owner_name}": "#{missing_arg_names.join('", "')}"|
            end
          end

          nil
        end
      end
    end
  end
end
