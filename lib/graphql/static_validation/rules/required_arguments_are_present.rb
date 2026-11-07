# frozen_string_literal: true
# typed: strict
module GraphQL
  module StaticValidation
    #--
    # @requires_ancestor: GraphQL::StaticValidation::BaseVisitor
    # @requires_ancestor: GraphQL::StaticValidation::BaseVisitor::ContextMethods
    module RequiredArgumentsArePresent
      #: (GraphQL::Language::Nodes::Document document, GraphQL::StaticValidation::ValidationContext context) -> void
      def initialize(document, context)
        super
        @required_args_cache = {}.compare_by_identity #: Hash[GraphQL::Schema::Field | singleton(GraphQL::Schema::Directive), Array[String]?]
      end

      #: (GraphQL::Language::Nodes::Field node, GraphQL::Language::Nodes::AbstractNode? _parent) -> void
      def on_field(node, _parent)
        assert_required_args(node, field_definition)
        super
      end

      #: (GraphQL::Language::Nodes::Directive node, GraphQL::Language::Nodes::AbstractNode? _parent) -> void
      def on_directive(node, _parent)
        directive_defn = context.schema_directives[node.name]
        assert_required_args(node, directive_defn)
        super
      end

      private

      #: (GraphQL::Language::Nodes::Field | GraphQL::Language::Nodes::Directive ast_node, (GraphQL::Schema::Field | singleton(GraphQL::Schema::Directive))? defn) -> void
      def assert_required_args(ast_node, defn)
        return unless defn

        # Cache required argument names per definition to avoid re-iterating
        # arguments for the same definition across field instances
        if @required_args_cache.key?(defn)
          required_argument_names = @required_args_cache[defn] #: Array[String]?
        else
          args = types.arguments(defn)
          required_argument_names = nil #: Array[String]?
          if !args.empty?
            args.each do |a|
              if a.type.kind.non_null? && !a.default_value? && types.argument(defn, a.name)
                (required_argument_names ||= []) << a.graphql_name
              end
            end
          end
          @required_args_cache[defn] = required_argument_names
        end

        return if required_argument_names.nil?

        present_argument_names = ast_node.arguments.map(&:name)
        missing_names = required_argument_names - present_argument_names
        if !missing_names.empty?
          # "Field" or "Directive"
          full_class_name = ast_node.class.name #: as !nil
          node_class_name = full_class_name.split("::").last #: as !nil
          add_error(GraphQL::StaticValidation::RequiredArgumentsArePresentError.new(
            "#{node_class_name} '#{ast_node.name}' is missing required arguments: #{missing_names.join(", ")}",
            nodes: ast_node,
            class_name: node_class_name,
            name: ast_node.name,
            arguments: "#{missing_names.join(", ")}"
          ))
        end
      end
    end
  end
end
