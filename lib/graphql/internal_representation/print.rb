# frozen_string_literal: true
module GraphQL
  module InternalRepresentation
    module Print
      module_function

      def print(schema, query_string)
        query = GraphQL::Query.new(schema, query_string)
        print_node(query.irep_selection)
      end

      def print_node(node, indent: 0)
        padding = " " * indent
        typed_children_padding = " " * (indent + 2)
        query_str = "".dup

        if !node.definition
          op_node = node.ast_node
          name = op_node.name ? " " + op_node.name : ""
          op_type = op_node.operation_type
          query_str << "#{op_type}#{name}"
        else
          if node.name == node.definition_name
            query_str << "#{padding}#{node.name}"
          else
            query_str << "#{padding}#{node.name}: #{node.definition_name}"
          end

          args = node.ast_nodes.map { |n| n.arguments.map(&:to_query_string).join(",") }.uniq
          query_str << args.map { |a| "(#{a})"}.join("|")
        end

        if node.typed_children.any?
          query_str << " {\n"
          node.typed_children.each do |type, children|
            query_str << "#{typed_children_padding}... on #{type.name} {\n"
            children.each do |name, child|
              query_str << print_node(child, indent: indent + 4)
            end
            query_str << "#{typed_children_padding}}\n"
          end
          query_str << "#{padding}}\n"
        else
          query_str << "\n"
        end

        query_str
      end
    end
  end
end
