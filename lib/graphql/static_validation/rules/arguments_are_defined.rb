# frozen_string_literal: true
# typed: strict
module GraphQL
  module StaticValidation
    #--
    # @requires_ancestor: GraphQL::StaticValidation::BaseVisitor
    module ArgumentsAreDefined
      #: (GraphQL::Language::Nodes::Argument node, GraphQL::Language::Nodes::Field | GraphQL::Language::Nodes::Directive | GraphQL::Language::Nodes::InputObject parent) -> void
      def on_argument(node, parent)
        parent_defn = parent_definition(parent)

        if parent_defn && types.argument(parent_defn, node.name)
          super
        elsif parent_defn
          kind_of_node = node_type(parent)
          error_arg_name = parent_name(parent, parent_defn)
          suggestion = if schema.did_you_mean
            arg_names = context.types.arguments(parent_defn).map(&:graphql_name)
            context.did_you_mean_suggestion(node.name, arg_names)
          end
          add_error(GraphQL::StaticValidation::ArgumentsAreDefinedError.new(
            "#{kind_of_node} '#{error_arg_name}' doesn't accept argument '#{node.name}'#{suggestion}",
            nodes: node,
            name: error_arg_name,
            type: kind_of_node,
            argument_name: node.name,
            parent: parent_defn
          ))
        else
          # Some other weird error
          super
        end
      end

      private

      # TODO smell: these methods are added to all visitors, since they're included in a module.
      #: (GraphQL::Language::Nodes::AbstractNode parent, GraphQL::Schema::Field | singleton(GraphQL::Schema::Directive) | GraphQL::Schema::Member::type_definition type_defn) -> String
      def parent_name(parent, type_defn)
        case parent
        when GraphQL::Language::Nodes::Field
          parent.alias || parent.name
        when GraphQL::Language::Nodes::InputObject
          type_defn.graphql_name
        when GraphQL::Language::Nodes::Argument, GraphQL::Language::Nodes::Directive
          parent.name
        else
          raise "Invariant: Unexpected parent #{parent.inspect} (#{parent.class})"
        end
      end

      #: (GraphQL::Language::Nodes::AbstractNode parent) -> String
      def node_type(parent)
        parent_class_name = parent.class.name #: as !nil
        parent_class_name.split("::").last #: as !nil
      end

      #: (GraphQL::Language::Nodes::AbstractNode parent) -> (GraphQL::Schema::Field | singleton(GraphQL::Schema::Directive) | GraphQL::Schema::Member::type_definition)?
      def parent_definition(parent)
        case parent
        when GraphQL::Language::Nodes::InputObject
          arg_defn = context.argument_definition
          if arg_defn.nil?
            nil
          else
            arg_ret_type = arg_defn.type.unwrap
            if arg_ret_type.kind.input_object?
              arg_ret_type
            else
              nil
            end
          end
        when GraphQL::Language::Nodes::Directive
          context.schema_directives[parent.name]
        when GraphQL::Language::Nodes::Field
          context.field_definition
        else
          raise "Unexpected argument parent: #{parent.class} (##{parent})"
        end
      end
    end
  end
end
