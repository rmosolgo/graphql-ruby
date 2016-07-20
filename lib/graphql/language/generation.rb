module GraphQL
  module Language
    module Generation
      extend self

      def generate(node, indent: "")
        case node
        when Nodes::Document
          node.definitions.map { |d| generate(d) }.join("\n\n")
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
          out << " = #{generate(node.default_value)}" unless node.default_value.nil?
          out
        when Nodes::VariableIdentifier
          "$#{node.name}"
        when Nodes::SchemaDefinition
          out = "schema {\n"
          out << "  query: #{node.query}\n" if node.query
          out << "  mutation: #{node.mutation}\n" if node.mutation
          out << "  subscription: #{node.subscription}\n" if node.subscription
          out << "}"
        when Nodes::ScalarTypeDefinition
          "scalar #{node.name}"
        when Nodes::ObjectTypeDefinition
          out = "type #{node.name}"
          out << " implements " << node.interfaces.join(", ") unless node.interfaces.empty?
          out << generate_field_definitions(node.fields)
        when Nodes::InputValueDefinition
          out = "#{node.name}: #{generate(node.type)}"
          out << " = #{generate(node.default_value)}" unless node.default_value.nil?
          out
        when Nodes::FieldDefinition
          out = node.name
          unless node.arguments.empty?
            out << "(" << node.arguments.map{ |arg| generate(arg) }.join(", ") << ")"
          end
          out << ": #{generate(node.type)}"
        when Nodes::InterfaceTypeDefinition
          out = "interface #{node.name}"
          out << generate_field_definitions(node.fields)
        when Nodes::UnionTypeDefinition
          "union #{node.name} = " + node.types.join(" | ")
        when Nodes::EnumTypeDefinition
          out = "enum #{node.name} {\n"
          node.values.each do |value|
            out << "  #{value}\n"
          end
          out << "}"
        when Nodes::InputObjectTypeDefinition
          out = "input #{node.name} {\n"
          node.fields.each do |field|
            out << "  #{generate(field)}\n"
          end
          out << "}"
        when Nodes::AbstractNode
          node.to_query_string(indent: indent)
        when FalseClass, Float, Integer, NilClass, String, TrueClass
          JSON.generate(node, quirks_mode: true)
        when Array
          "[#{node.map { |v| generate(v) }.join(", ")}]"
        when Hash
          "{ #{node.map { |k, v| "#{k}: #{generate(v)}" }.join(", ")} }"
        else
          raise TypeError
        end
      end

      private

      def generate_directives(directives)
        if directives.any?
          directives.map { |d| " #{generate(d)}" }.join
        else
          ""
        end
      end

      def generate_selections(selections, indent: "")
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

      def generate_field_definitions(fields)
        out = " {\n"
        fields.each do |field|
          out << "  #{generate(field)}\n"
        end
        out << "}"
      end
    end
  end
end
