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
            if !arg_ret_type.is_a?(GraphQL::InputObjectType)
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
          if arg_defn
            begin
              valid = context.valid_literal?(node.value, arg_defn.type)
            rescue GraphQL::CoercionError => err
              context.schema.error_bubbling
              if !context.schema.error_bubbling && !arg_defn.type.unwrap.kind.scalar?
                # if error bubbling is disabled and the arg that caused this error isn't a scalar then
                # short-circuit here so we avoid bubbling this up to whatever input_object / array contains us
                return super
              end
              error = GraphQL::StaticValidation::ArgumentLiteralsAreCompatibleError.new(err.message, nodes: parent, type: "CoercionError", extensions: err.extensions)
            rescue GraphQL::LiteralValidationError => err
              # check to see if the ast node that caused the error to be raised is
              # the same as the node we were checking here.
              arg_type = arg_defn.type
              if arg_type.kind.non_null?
                arg_type = arg_type.of_type
              end

              matched = if arg_type.kind.list?
                # for a list we claim an error if the node is contained in our list
                Array(node.value).include?(err.ast_value)
              elsif arg_type.kind.input_object? && node.value.is_a?(GraphQL::Language::Nodes::InputObject)
                # for an input object we check the arguments
                node.value.arguments.include?(err.ast_value)
              else
                # otherwise we just check equality
                node.value == (err.ast_value)
              end
              if !matched
                # This node isn't the node that caused the error,
                # So halt this visit but continue visiting the rest of the tree
                return super
              end
            end

            if !valid
              error ||= begin
                kind_of_node = node_type(parent)
                error_arg_name = parent_name(parent, parent_defn)

                GraphQL::StaticValidation::ArgumentLiteralsAreCompatibleError.new(
                  "Argument '#{node.name}' on #{kind_of_node} '#{error_arg_name}' has an invalid value. Expected type '#{arg_defn.type}'.",
                  nodes: parent,
                  type: kind_of_node,
                  argument: node.name
                )
              end
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
          parent.name
        end
      end

      def node_type(parent)
        parent.class.name.split("::").last
      end
    end
  end
end
