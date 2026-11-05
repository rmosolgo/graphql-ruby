# frozen_string_literal: true
# typed: true
module GraphQL
  module StaticValidation
    #--
    # @requires_ancestor: GraphQL::StaticValidation::BaseVisitor
    # @requires_ancestor: GraphQL::StaticValidation::RequiredInputObjectAttributesArePresent
    module OneOfInputObjectsAreValid
      #: (GraphQL::Language::Nodes::InputObject node, GraphQL::Language::Nodes::AbstractNode parent) -> void
      def on_input_object(node, parent)
        return super unless parent.is_a?(GraphQL::Language::Nodes::Argument)

        parent_type = get_parent_type(context, parent)
        return super unless parent_type && parent_type.kind.input_object? && parent_type.one_of?

        validate_one_of_input_object(node, context, parent_type)
        super
      end

      private

      #: (GraphQL::Language::Nodes::InputObject ast_node, GraphQL::StaticValidation::ValidationContext context, singleton(GraphQL::Schema::InputObject) parent_type) -> void
      def validate_one_of_input_object(ast_node, context, parent_type)
        present_fields = ast_node.arguments.map(&:name)
        input_object_type = parent_type.to_type_signature

        if present_fields.count != 1
          add_error(
            OneOfInputObjectsAreValidError.new(
              "OneOf Input Object '#{input_object_type}' must specify exactly one key.",
              path: context.path,
              nodes: ast_node,
              input_object_type: input_object_type
            )
          )
          return
        end

        field = present_fields.first
        # `present_fields.count == 1` was checked above:
        argument = ast_node.arguments.first #: as !nil
        value = argument.value

        if value.is_a?(GraphQL::Language::Nodes::NullValue)
          add_error(
            OneOfInputObjectsAreValidError.new(
              "Argument '#{input_object_type}.#{field}' must be non-null.",
              path: [*context.path, field],
              nodes: argument,
              input_object_type: input_object_type
            )
          )
          return
        end

        if value.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
          variable_name = value.name
          variable_definition = @declared_variables && @declared_variables[variable_name]
          # Undeclared variables are reported by VariablesAreUsedAndDefined
          return if variable_definition.nil?
          variable_type = variable_definition.type

          unless variable_type.is_a?(GraphQL::Language::Nodes::NonNullType)
            add_error(
              OneOfInputObjectsAreValidError.new(
                "Variable '#{variable_name}' must be non-nullable to be used for OneOf Input Object '#{input_object_type}'.",
                path: [*context.path, field],
                nodes: ast_node,
                input_object_type: input_object_type
              )
            )
          end
        end
      end
    end
  end
end
