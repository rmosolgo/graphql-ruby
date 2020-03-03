# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module ArgumentLiteralsAreCompatible
      # TODO dedup with ArgumentsAreDefined
      def on_argument(node, parent)
        parent_defn = case parent
        when GraphQL::Language::Nodes::InputObject
          arg_defn = context.argument_definition
          if arg_defn.nil?
            nil
          else
            arg_ret_type = arg_defn.type.unwrap
            if !arg_ret_type.kind.input_object?
              nil
            else
              arg_ret_type
            end
          end
        when GraphQL::Language::Nodes::Directive
          context.schema.directives[parent.name]
        when GraphQL::Language::Nodes::Field
          context.field_definition
        else
          raise "Unexpected argument parent: #{parent.class} (##{parent})"
        end

        if parent_defn && !node.value.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
          arg_defn = parent_defn.arguments[node.name]
          validation_error = nil
          if arg_defn
            begin
              valid = context.validate_literal(node.value, arg_defn.type)
              if valid.is_a?(GraphQL::Query::InputValidationResult)
                validation_error = valid
                valid = validation_error.valid?
              end
            rescue GraphQL::LiteralValidationError => validation_error
              # check to see if the ast node that caused the error to be raised is
              # the same as the node we were checking here.
              arg_type = arg_defn.type
              if arg_type.kind.non_null?
                arg_type = arg_type.of_type
              end

              matched = if arg_type.kind.list?
                # for a list we claim an error if the node is contained in our list
                Array(node.value).include?(validation_error.ast_value)
              elsif arg_type.kind.input_object? && node.value.is_a?(GraphQL::Language::Nodes::InputObject)
                # for an input object we check the arguments
                node.value.arguments.include?(validation_error.ast_value)
              else
                # otherwise we just check equality
                node.value == validation_error.ast_value
              end
              if !matched
                # This node isn't the node that caused the error,
                # So halt this visit but continue visiting the rest of the tree
                return super
              end
            end

            if !valid
              kind_of_node = node_type(parent)
              error_arg_name = parent_name(parent, parent_defn)
              string_value = if node.value == Float::INFINITY
                ""
              else
                " (#{GraphQL::Language::Printer.new.print(node.value)})"
              end

              if validation_error
                problems = validation_error.problems
                first_problem = problems && problems.first
                if first_problem
                  message = first_problem["message"]
                  if message
                    coerce_extensions = first_problem["extensions"] || {
                      "typeName" => "CoercionError",
                      "code" => "argumentLiteralsIncompatible"
                    }
                  end
                end
              end

              error_options = {
                nodes: parent,
                type: kind_of_node,
                argument: node.name
              }
              if coerce_extensions
                error_options[:coerce_extensions] = coerce_extensions
              end

              message ||= "Argument '#{node.name}' on #{kind_of_node} '#{error_arg_name}' has an invalid value#{string_value}. Expected type '#{arg_defn.type.to_type_signature}'."

              error = GraphQL::StaticValidation::ArgumentLiteralsAreCompatibleError.new(
                message,
                **error_options
              )

              add_error(error)
            end
          end
        end

        super
      end


      private

      def parent_name(parent, type_defn)
        if parent.is_a?(GraphQL::Language::Nodes::Field)
          parent.alias || parent.name
        elsif parent.is_a?(GraphQL::Language::Nodes::InputObject)
          type_defn.name
        else
          parent.graphql_name
        end
      end

      def node_type(parent)
        parent.class.name.split("::").last
      end
    end
  end
end
