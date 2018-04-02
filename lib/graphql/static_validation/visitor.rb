# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class Visitor < GraphQL::Language::Visitor
      # Since these modules override methods,
      # order matters. Earlier ones may skip later ones.
      include MutationRootExists
      include FragmentTypesExist

      def initialize(document, context)
        @context = context
        @schema = context.schema
        @object_types = []
        @field_definitions = []
        @directive_definitions = []
        @argument_definitions = []
        @path = []

        super(document)
      end

      attr_reader :context

      def on_operation_definition(node, parent)
        object_type = @schema.root_type_for_operation(node.operation_type)
        @object_types.push(object_type)
        @path.push("#{node.operation_type}#{node.name ? " #{node.name}" : ""}")
        super
        @object_types.pop
        @path.pop
      end

      def on_fragment_definition(node, parent)
        on_fragment_with_type(node) do
          @path.push("fragment #{node.name}")
          super
        end
      end

      def on_inline_fragment(node, parent)
        on_fragment_with_type(node) do
          @path.push("...#{node.type ? " on #{node.type.to_query_string}" : ""}")
          super
        end
      end

      def on_field(node, parent)
        parent_type = @object_types.last.unwrap
        field_definition = @schema.get_field(parent_type, node.name)
        @field_definitions.push(field_definition)
        if !field_definition.nil?
          next_object_type = field_definition.type
          @object_types.push(next_object_type)
        else
          @object_types.push(nil)
        end
        @path.push(node.alias || node.name)
        super
        @field_definitions.pop
        @object_types.pop
        @path.pop
      end

      def on_directive(node, parent)
        directive_defn = @schema.directives[node.name]
        @directive_definitions.push(directive_defn)
        super
        @directive_definitions.pop
      end

      def on_argument(node, parent)
        argument_defn = if (arg = @argument_definitions.last)
          arg_type = arg.type.unwrap
          if arg_type.kind.input_object?
            arg_type.input_fields[node.name]
          else
            nil
          end
        elsif (directive_defn = @directive_definitions.last)
          directive_defn.arguments[node.name]
        elsif (field_defn = @field_definitions.last)
          field_defn.arguments[node.name]
        else
          nil
        end

        @argument_definitions.push(argument_defn)
        @path.push(node.name)
        super
        @argument_definitions.pop
        @path.pop
      end

      def on_fragment_spread(node, parent)
        @path.push("... #{node.name}")
        super
        @path.pop
      end

      private

      # Error `message` is located at `node`
      def add_error(message, nodes, path: nil)
        path ||= @path.dup
        nodes = Array(nodes)
        m = GraphQL::StaticValidation::Message.new(message, nodes: nodes, path: path)
        context.errors << m
      end

      def on_fragment_with_type(node)
        object_type = if node.type
          @schema.types.fetch(node.type.name, nil)
        else
          @object_types.last
        end
        if !object_type.nil?
          object_type = object_type.unwrap
        end
        @object_types.push(object_type)
        yield(node)
        @object_types.pop
        @path.pop
      end
    end
  end
end
