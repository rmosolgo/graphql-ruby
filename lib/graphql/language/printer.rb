# frozen_string_literal: true
module GraphQL
  module Language
    class Printer
      # Turn an arbitrary AST node back into a string.
      #
      # @example Turning a document into a query string
      #    document = GraphQL.parse(query_string)
      #    GraphQL::Language::Printer.new.print(document)
      #    # => "{ ... }"
      #
      #
      # @example Building a custom printer
      #
      #  class MyPrinter < GraphQL::Language::Printer
      #    def print_argument(arg)
      #      "#{arg.name}: <HIDDEN>"
      #    end
      #  end
      #
      #  MyPrinter.new.print(document)
      #  # => "mutation { pay(creditCard: <HIDDEN>) { success } }"
      #
      #
      # @param indent [String] Whitespace to add to the printed node
      # @return [String] Valid GraphQL for `node`
      def print(node, indent: "")
        print_node(node, indent: indent)
      end

      protected

      def print_document(document)
        document.definitions.map { |d| print_node(d) }.join("\n\n")
      end

      def print_argument(argument)
        "#{argument.name}: #{print_node(argument.value)}".dup
      end

      def print_directive(directive)
        out = "@#{directive.name}".dup

        if directive.arguments.any?
          out << "(#{directive.arguments.map { |a| print_argument(a) }.join(", ")})"
        end

        out
      end

      def print_enum(enum)
        "#{enum.name}".dup
      end

      def print_null_value
        "null".dup
      end

      def print_field(field, indent: "")
        out = "#{indent}".dup
        out << "#{field.alias}: " if field.alias
        out << "#{field.name}"
        out << "(#{field.arguments.map { |a| print_argument(a) }.join(", ")})" if field.arguments.any?
        out << print_directives(field.directives)
        out << print_selections(field.selections, indent: indent)
        out
      end

      def print_fragment_definition(fragment_def, indent: "")
        out = "#{indent}fragment #{fragment_def.name}".dup
        if fragment_def.type
          out << " on #{print_node(fragment_def.type)}"
        end
        out << print_directives(fragment_def.directives)
        out << print_selections(fragment_def.selections, indent: indent)
        out
      end

      def print_fragment_spread(fragment_spread, indent: "")
        out = "#{indent}...#{fragment_spread.name}".dup
        out << print_directives(fragment_spread.directives)
        out
      end

      def print_inline_fragment(inline_fragment, indent: "")
        out = "#{indent}...".dup
        if inline_fragment.type
          out << " on #{print_node(inline_fragment.type)}"
        end
        out << print_directives(inline_fragment.directives)
        out << print_selections(inline_fragment.selections, indent: indent)
        out
      end

      def print_input_object(input_object)
        "{#{input_object.arguments.map { |a| print_argument(a) }.join(", ")}}"
      end

      def print_list_type(list_type)
        "[#{print_node(list_type.of_type)}]".dup
      end

      def print_non_null_type(non_null_type)
        "#{print_node(non_null_type.of_type)}!".dup
      end

      def print_operation_definition(operation_definition, indent: "")
        out = "#{indent}#{operation_definition.operation_type}".dup
        out << " #{operation_definition.name}" if operation_definition.name

        if operation_definition.variables.any?
          out << "(#{operation_definition.variables.map { |v| print_variable_definition(v) }.join(", ")})"
        end

        out << print_directives(operation_definition.directives)
        out << print_selections(operation_definition.selections, indent: indent)
        out
      end

      def print_type_name(type_name)
        "#{type_name.name}".dup
      end

      def print_variable_definition(variable_definition)
        out = "$#{variable_definition.name}: #{print_node(variable_definition.type)}".dup
        out << " = #{print_node(variable_definition.default_value)}" unless variable_definition.default_value.nil?
        out
      end

      def print_variable_identifier(variable_identifier)
        "$#{variable_identifier.name}".dup
      end

      def print_schema_definition(schema)
        if (schema.query.nil? || schema.query == 'Query') &&
           (schema.mutation.nil? || schema.mutation == 'Mutation') &&
           (schema.subscription.nil? || schema.subscription == 'Subscription') &&
           (schema.directives.empty?)
          return
        end

        out = "schema".dup
        if schema.directives.any?
          schema.directives.each do |dir|
            out << "\n  "
            out << print_node(dir)
          end
          out << "\n{"
        else
          out << " {\n"
        end
        out << "  query: #{schema.query}\n" if schema.query
        out << "  mutation: #{schema.mutation}\n" if schema.mutation
        out << "  subscription: #{schema.subscription}\n" if schema.subscription
        out << "}"
      end

      def print_scalar_type_definition(scalar_type)
        out = print_description(scalar_type)
        out << "scalar #{scalar_type.name}"
        out << print_directives(scalar_type.directives)
      end

      def print_object_type_definition(object_type)
        out = print_description(object_type)
        out << "type #{object_type.name}"
        out << " implements " << object_type.interfaces.map(&:name).join(" & ") unless object_type.interfaces.empty?
        out << print_directives(object_type.directives)
        out << print_field_definitions(object_type.fields)
      end

      def print_input_value_definition(input_value)
        out = "#{input_value.name}: #{print_node(input_value.type)}".dup
        out << " = #{print_node(input_value.default_value)}" unless input_value.default_value.nil?
        out << print_directives(input_value.directives)
      end

      def print_arguments(arguments, indent: "")
        if arguments.all?{ |arg| !arg.description }
          return "(#{arguments.map{ |arg| print_input_value_definition(arg) }.join(", ")})"
        end

        out = "(\n".dup
        out << arguments.map.with_index{ |arg, i|
          "#{print_description(arg, indent: "  " + indent, first_in_block: i == 0)}  #{indent}"\
          "#{print_input_value_definition(arg)}"
        }.join("\n")
        out << "\n#{indent})"
      end

      def print_field_definition(field)
        out = field.name.dup
        unless field.arguments.empty?
          out << print_arguments(field.arguments, indent: "  ")
        end
        out << ": #{print_node(field.type)}"
        out << print_directives(field.directives)
      end

      def print_interface_type_definition(interface_type)
        out = print_description(interface_type)
        out << "interface #{interface_type.name}"
        out << print_directives(interface_type.directives)
        out << print_field_definitions(interface_type.fields)
      end

      def print_union_type_definition(union_type)
        out = print_description(union_type)
        out << "union #{union_type.name}"
        out << print_directives(union_type.directives)
        out << " = " + union_type.types.map(&:name).join(" | ")
      end

      def print_enum_type_definition(enum_type)
        out = print_description(enum_type)
        out << "enum #{enum_type.name}#{print_directives(enum_type.directives)} {\n"
        enum_type.values.each.with_index do |value, i|
          out << print_description(value, indent: '  ', first_in_block: i == 0)
          out << print_enum_value_definition(value)
        end
        out << "}"
      end

      def print_enum_value_definition(enum_value)
        out = "  #{enum_value.name}".dup
        out << print_directives(enum_value.directives)
        out << "\n"
      end

      def print_input_object_type_definition(input_object_type)
        out = print_description(input_object_type)
        out << "input #{input_object_type.name}"
        out << print_directives(input_object_type.directives)
        out << " {\n"
        input_object_type.fields.each.with_index do |field, i|
          out << print_description(field, indent: '  ', first_in_block: i == 0)
          out << "  #{print_input_value_definition(field)}\n"
        end
        out << "}"
      end

      def print_directive_definition(directive)
        out = print_description(directive)
        out << "directive @#{directive.name}"

        if directive.arguments.any?
          out << print_arguments(directive.arguments)
        end

        out << " on #{directive.locations.map(&:name).join(' | ')}"
      end

      def print_description(node, indent: "", first_in_block: true)
        return ''.dup unless node.description

        description = indent != '' && !first_in_block ? "\n".dup : "".dup
        description << GraphQL::Language::BlockString.print(node.description, indent: indent)
      end

      def print_field_definitions(fields)
        out = " {\n".dup
        fields.each.with_index do |field, i|
          out << print_description(field, indent: '  ', first_in_block: i == 0)
          out << "  #{print_field_definition(field)}\n"
        end
        out << "}"
      end

      def print_directives(directives)
        if directives.any?
          directives.map { |d| " #{print_directive(d)}" }.join
        else
          ""
        end
      end

      def print_selections(selections, indent: "")
        if selections.any?
          out = " {\n".dup
          selections.each do |selection|
            out << print_node(selection, indent: indent + "  ") << "\n"
          end
          out << "#{indent}}"
        else
          ""
        end
      end

      def print_node(node, indent: "")
        case node
        when Nodes::Document
          print_document(node)
        when Nodes::Argument
          print_argument(node)
        when Nodes::Directive
          print_directive(node)
        when Nodes::Enum
          print_enum(node)
        when Nodes::NullValue
          print_null_value
        when Nodes::Field
          print_field(node, indent: indent)
        when Nodes::FragmentDefinition
          print_fragment_definition(node, indent: indent)
        when Nodes::FragmentSpread
          print_fragment_spread(node, indent: indent)
        when Nodes::InlineFragment
          print_inline_fragment(node, indent: indent)
        when Nodes::InputObject
          print_input_object(node)
        when Nodes::ListType
          print_list_type(node)
        when Nodes::NonNullType
          print_non_null_type(node)
        when Nodes::OperationDefinition
          print_operation_definition(node, indent: indent)
        when Nodes::TypeName
          print_type_name(node)
        when Nodes::VariableDefinition
          print_variable_definition(node)
        when Nodes::VariableIdentifier
          print_variable_identifier(node)
        when Nodes::SchemaDefinition
          print_schema_definition(node)
        when Nodes::ScalarTypeDefinition
          print_scalar_type_definition(node)
        when Nodes::ObjectTypeDefinition
          print_object_type_definition(node)
        when Nodes::InputValueDefinition
          print_input_value_definition(node)
        when Nodes::FieldDefinition
          print_field_definition(node)
        when Nodes::InterfaceTypeDefinition
          print_interface_type_definition(node)
        when Nodes::UnionTypeDefinition
          print_union_type_definition(node)
        when Nodes::EnumTypeDefinition
          print_enum_type_definition(node)
        when Nodes::EnumValueDefinition
          print_enum_value_definition(node)
        when Nodes::InputObjectTypeDefinition
          print_input_object_type_definition(node)
        when Nodes::DirectiveDefinition
          print_directive_definition(node)
        when FalseClass, Float, Integer, NilClass, String, TrueClass, Symbol
          GraphQL::Language.serialize(node)
        when Array
          "[#{node.map { |v| print_node(v) }.join(", ")}]".dup
        when Hash
          "{#{node.map { |k, v| "#{k}: #{print_node(v)}" }.join(", ")}}".dup
        else
          GraphQL::Language.serialize(node.to_s)
        end
      end

      private

      attr_reader :node
    end
  end
end
