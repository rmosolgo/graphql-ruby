module GraphQL
  module StaticAnalysis
    class TypeCheck
      module RequiredArguments
        module_function

        def find_error(parent, argument_owner, node, observed_argument_names)
          if argument_owner == AnyField || argument_owner == AnyInput || argument_owner == AnyDirective
            nil
          else
            all_arguments = argument_owner
              .arguments
              .values

            # TODO: can we memoize required arguments?
            required_arg_names = all_arguments
              .select { |arg| arg.type.kind.non_null? }
              .map(&:name)

            allowed_arg_names = all_arguments.map(&:name)

            # Check for any missing-but-required arguments
            missing_arg_names = required_arg_names - observed_argument_names
            # Check for undefined-but-present arguments
            extra_arg_names = observed_argument_names - allowed_arg_names
            if missing_arg_names.any? || extra_arg_names.any?
              owner_name = case argument_owner
              when GraphQL::Field
                "#{parent.name}.#{argument_owner.name}"
              when GraphQL::Directive
                "@#{argument_owner.name}"
              else GraphQL::Argument
                argument_owner.name
              end

              error_message = %|Arguments for "#{owner_name}" are invalid: |

              if missing_arg_names.any?
                error_message << %|missing required arguments ("#{missing_arg_names.join('", "')}")|
              end

              if extra_arg_names.any?
                if missing_arg_names.any?
                  error_message << ", "
                end
                error_message << %|undefined arguments ("#{extra_arg_names.join('", "')}")|
              end


              error_message
            else
              nil
            end
          end
        end
      end
    end
  end
end
