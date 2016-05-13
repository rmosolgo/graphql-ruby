require "graphql/language/nodes"

module GraphQL
  module Language
    module Nodes
      class Document < AbstractNode
        def to_query_string
          Generation.generate(self)
        end
      end
    end

    module Generation
      def self.generate(node, indent: "")
        case node
        when Nodes::Document
          node.definitions.map { |d| generate(d) }.join("\n")
        when Nodes::Argument
          "#{node.name}: #{generate(node.value)}"
        when Nodes::Directive
          "@#{node.name}(#{node.arguments.map { |a| generate(a) }.join(", ")})"
        when Nodes::Enum
          "#{node.name}"
        when Nodes::Field
          out = "#{indent}"
          out << "#{node.alias}: " if node.alias
          out << "#{node.name}"
          out << "(#{node.arguments.map { |a| generate(a) }.join(", ")})" if node.arguments.any?
          out << generate_directives(node.directives)
          out << generate_selections(node.selections, indent: indent)
          out
        when Nodes::FragmentDefinition
          out = "#{indent}fragment #{node.name}"
          out << " on #{node.type}" if node.type
          out << generate_directives(node.directives)
          out << generate_selections(node.selections, indent: indent)
          out

        when Nodes::FragmentSpread
          out = "#{indent}... #{node.name}"
          out << generate_directives(node.directives)
          out
        when Nodes::InlineFragment
          out = "#{indent}..."
          out << " on #{node.type}" if node.type
          out << generate_directives(node.directives)
          out << generate_selections(node.selections, indent: indent)
          out
        when Nodes::InputObject
          generate(node.to_h)
        when Nodes::ListType
          "[#{generate(node.of_type)}]"
        when Nodes::NonNullType
          "#{generate(node.of_type)}!"
        when Nodes::OperationDefinition
          out = "#{indent}#{node.operation_type}"
          out << " #{node.name}" if node.name
          out << "(#{node.variables.map { |v| generate(v) }.join(", ")})" if node.variables.any?
          out << generate_directives(node.directives)
          out << generate_selections(node.selections, indent: indent)
          out
        when Nodes::TypeName
          "#{node.name}"
        when Nodes::VariableDefinition
          out = "$#{node.name}: #{generate(node.type)}"
          out << " = #{generate(node.default_value)}" if node.default_value
          out
        when Nodes::VariableIdentifier
          "$#{node.name}"
        when Nodes::AbstractNode
          node.to_query_string(indent: indent)
        when FalseClass, Float, Integer, NilClass, String, TrueClass
          JSON.generate(node, quirks_mode: true)
        when Array
          "[#{node.map { |v| generate(v) }.join(", ")}]"
        when Hash
          "{#{node.map { |k, v| "#{k}: #{generate(v)}" }.join(", ")}}"
        else
          raise TypeError
        end
      end

      def self.generate_directives(directives)
        if directives.any?
          directives.map { |d| " #{generate(d)}" }.join
        else
          ""
        end
      end

      def self.generate_selections(selections, indent: "")
        if selections.any?
          out = " {\n"
          selections.each do |selection|
            out << generate(selection, indent: indent + "  ") << "\n"
          end
          out << "#{indent}}"
        else
          ""
        end
      end
    end
  end
end
