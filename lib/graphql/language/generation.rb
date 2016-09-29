module GraphQL
  module Language
    # Exposes {.generate}, which turns AST nodes back into query strings.
    module Generation
      extend self

      # Turn an AST node back into a string.
      #
      # @example Turning a document into a query
      #    document = GraphQL.parse(query_string)
      #    GraphQL::Language::Generation.generate(document)
      #    # => "{ ... }"
      #
      # @param node [GraphQL::Language::Nodes::AbstractNode] an AST node to recursively stringify
      # @param indent [String] Whitespace to add to each printed node
      # @return [String] Valid GraphQL for `node`
      def generate(node, indent: "")
        case node
        when Nodes::Document
          node.definitions.map { |d| generate(d) }.join("\n\n")
        when Nodes::Argument
          "#{node.name}: #{generate(node.value)}"
        when Nodes::Directive
          out = "@#{node.name}"
          out << "(#{node.arguments.map { |a| generate(a) }.join(", ")})" if node.arguments.any?
          out
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
          out = "#{indent}...#{node.name}"
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
          out = "scalar #{node.name}"
          out << generate_directives(node.directives)
        when Nodes::ObjectTypeDefinition
          out = "type #{node.name}"
          out << generate_directives(node.directives)
          out << " implements " << node.interfaces.join(", ") unless node.interfaces.empty?
          out << generate_field_definitions(node.fields)
        when Nodes::InputValueDefinition
          out = "#{node.name}: #{generate(node.type)}"
          out << " = #{generate(node.default_value)}" unless node.default_value.nil?
          out << generate_directives(node.directives)
        when Nodes::FieldDefinition
          out = node.name.dup
          unless node.arguments.empty?
            out << "(" << node.arguments.map{ |arg| generate(arg) }.join(", ") << ")"
          end
          out << ": #{generate(node.type)}"
          out << generate_directives(node.directives)
        when Nodes::InterfaceTypeDefinition
          out = "interface #{node.name}"
          out << generate_directives(node.directives)
          out << generate_field_definitions(node.fields)
        when Nodes::UnionTypeDefinition
          out = "union #{node.name}"
          out << generate_directives(node.directives)
          out << " = " + node.types.join(" | ")
        when Nodes::EnumTypeDefinition
          out = "enum #{node.name}#{generate_directives(node.directives)} {\n"
          node.values.each do |value|
            out << generate(value)
          end
          out << "}"
        when Nodes::EnumValueDefinition
          out = "  #{node.name}"
          out << generate_directives(node.directives)
          out << "\n"
        when Nodes::InputObjectTypeDefinition
          out = "input #{node.name}"
          out << generate_directives(node.directives)
          out << " {\n"
          node.fields.each do |field|
            out << "  #{generate(field)}\n"
          end
          out << "}"
        when Nodes::DirectiveDefinition
          out = "directive @#{node.name}"
          out << "(#{node.arguments.map { |a| generate(a) }.join(", ")})" if node.arguments.any?
          out << " on #{node.locations.join(' | ')}"
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
