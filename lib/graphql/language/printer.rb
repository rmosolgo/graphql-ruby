# frozen_string_literal: true
module GraphQL
  module Language
    class Printer
      OMISSION = "... (truncated)"

      class TruncatableBuffer
        class TruncateSizeReached < StandardError; end

        DEFAULT_INIT_CAPACITY = 500

        def initialize(truncate_size: nil)
          @out = String.new(capacity: truncate_size || DEFAULT_INIT_CAPACITY)
          @truncate_size = truncate_size
        end

        def <<(other)
          if @truncate_size && (@out.size + other.size) > @truncate_size
            @out << other.slice(0, @truncate_size - @out.size)
            raise(TruncateSizeReached, "Truncate size reached")
          else
            @out << other
          end
        end

        def to_string
          @out
        end
      end

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
      # @param node [Nodes::AbstractNode]
      # @param indent [String] Whitespace to add to the printed node
      # @param truncate_size [Integer, nil] The size to truncate to.
      # @return [String] Valid GraphQL for `node`
      def print(node, indent: "", truncate_size: nil)
        truncate_size = truncate_size ? [truncate_size - OMISSION.size, 0].max : nil
        @out = TruncatableBuffer.new(truncate_size: @truncate_size)
        print_node(node, indent:)
        @out.to_string
      rescue TruncatableBuffer::TruncateSizeReached
        @out.to_string << OMISSION
      end

      protected

      def print_document(document)
        document.definitions.each_with_index do |d, i|
          print_node(d)
          @out << "\n\n" if i < document.definitions.size - 1
        end
      end

      def print_argument(argument)
        @out << "#{argument.name}: "
        print_node(argument.value)
      end

      def print_input_object(input_object)
        @out << "{"
        input_object.arguments.each_with_index do |a, i|
          print_argument(a)
          @out << ", " if i < input_object.arguments.size - 1
        end
        @out << "}"
      end

      def print_directive(directive)
        @out << "@#{directive.name}"

        if directive.arguments.any?
          @out << "("
          directive.arguments.each_with_index do |a, i|
            print_argument(a)
            @out << ", " if i < directive.arguments.size - 1
          end
          @out << ")"
        end
      end

      def print_enum(enum)
        @out << enum.name
      end

      def print_null_value
        @out << "null"
      end

      def print_field(field, indent: "")
        @out << indent
        @out << "#{field.alias}: " if field.alias
        @out << field.name
        if field.arguments.any?
          @out << "("
          field.arguments.each_with_index do |a, i|
            print_argument(a)
            @out << ", " if i < field.arguments.size - 1
          end
          @out << ")"
        end
        print_directives(field.directives)
        print_selections(field.selections, indent:)
      end

      def print_fragment_definition(fragment_def, indent: "")
        @out << "#{indent}fragment #{fragment_def.name}"
        if fragment_def.type
          @out << " on "
          print_node(fragment_def.type)
        end
        print_directives(fragment_def.directives)
        print_selections(fragment_def.selections, indent:)
      end

      def print_fragment_spread(fragment_spread, indent: "")
        @out << "#{indent}...#{fragment_spread.name}"
        print_directives(fragment_spread.directives)
      end

      def print_inline_fragment(inline_fragment, indent: "")
        @out << "#{indent}..."
        if inline_fragment.type
          @out << " on "
          print_node(inline_fragment.type)
        end
        print_directives(inline_fragment.directives)
        print_selections(inline_fragment.selections, indent:)
      end

      def print_list_type(list_type)
        @out << "["
        print_node(list_type.of_type)
        @out << "]"
      end

      def print_non_null_type(non_null_type)
        print_node(non_null_type.of_type)
        @out << "!"
      end

      def print_operation_definition(operation_definition, indent: "")
        @out << "#{indent}#{operation_definition.operation_type}"
        @out << " #{operation_definition.name}" if operation_definition.name

        if operation_definition.variables.any?
          @out << "("
          operation_definition.variables.each_with_index do |v, i|
            print_variable_definition(v)
            @out << ", " if i < operation_definition.variables.size - 1
          end
          @out << ")"
        end

        print_directives(operation_definition.directives)
        print_selections(operation_definition.selections, indent:)
      end

      def print_type_name(type_name)
        @out << type_name.name
      end

      def print_variable_definition(variable_definition)
        @out << "$#{variable_definition.name}: "
        print_node(variable_definition.type)
        unless variable_definition.default_value.nil?
          @out << " = "
          print_node(variable_definition.default_value)
        end
      end

      def print_variable_identifier(variable_identifier)
        @out << "$#{variable_identifier.name}"
      end


      def print_schema_definition(schema)
        has_conventional_names =
          (schema.query.nil? || schema.query == 'Query') &&
          (schema.mutation.nil? || schema.mutation == 'Mutation') &&
          (schema.subscription.nil? || schema.subscription == 'Subscription')

        if has_conventional_names && schema.directives.empty?
          return
        end

        @out << "schema"

        if schema.directives.any?
          schema.directives.each do |dir|
            @out << "\n  "
            print_node(dir)
          end

          if !has_conventional_names
            @out << "\n"
          end
        end

        if !has_conventional_names
          if schema.directives.empty?
            @out << " "
          end
          @out << "{\n"
          @out << "  query: #{schema.query}\n" if schema.query
          @out << "  mutation: #{schema.mutation}\n" if schema.mutation
          @out << "  subscription: #{schema.subscription}\n" if schema.subscription
          @out << "}"
        end
      end

      def print_scalar_type_definition(scalar_type)
        print_description(scalar_type)
        @out << "scalar #{scalar_type.name}"
        print_directives(scalar_type.directives)
      end

      def print_object_type_definition(object_type)
        print_description(object_type)
        @out << "type #{object_type.name}"
        print_implements(object_type) unless object_type.interfaces.empty?
        print_directives(object_type.directives)
        print_field_definitions(object_type.fields)
      end

      def print_implements(type)
        @out << " implements #{type.interfaces.map(&:name).join(" & ")}"
      end

      def print_input_value_definition(input_value)
        @out << "#{input_value.name}: "
        print_node(input_value.type)
        unless input_value.default_value.nil?
          @out << " = "
          print_node(input_value.default_value)
        end
        print_directives(input_value.directives)
      end

      def print_arguments(arguments, indent: "")
        if arguments.all? { |arg| !arg.description }
          @out << "("
          arguments.each_with_index do |arg, i|
            print_input_value_definition(arg)
            @out << ", " if i < arguments.size - 1
          end
          @out << ")"
          return
        end

        @out << "(\n"
        arguments.each_with_index do |arg, i|
          print_description(arg, indent: "  " + indent, first_in_block: i == 0)
          @out << "  #{@indent}"
          print_input_value_definition(arg)
          @out << "\n" if i < arguments.size - 1
        end
        @out << "\n#{@indent})"
      end

      def print_field_definition(field)
        @out << field.name
        unless field.arguments.empty?
          print_arguments(field.arguments, indent: "  ")
        end
        @out << ": "
        print_node(field.type)
        print_directives(field.directives)
      end

      def print_interface_type_definition(interface_type)
        print_description(interface_type)
        @out << "interface #{interface_type.name}"
        print_implements(interface_type) if interface_type.interfaces.any?
        print_directives(interface_type.directives)
        print_field_definitions(interface_type.fields)
      end

      def print_union_type_definition(union_type)
        print_description(union_type)
        @out << "union #{union_type.name}"
        print_directives(union_type.directives)
        @out << " = " + union_type.types.map(&:name).join(" | ")
      end

      def print_enum_type_definition(enum_type)
        print_description(enum_type)
        @out << "enum #{enum_type.name}"
        print_directives(enum_type.directives)
        @out << " {\n"
        enum_type.values.each.with_index do |value, i|
          print_description(value, indent: "  ", first_in_block: i == 0)
          print_enum_value_definition(value)
        end
        @out << "}"
      end

      def print_enum_value_definition(enum_value)
        @out << "  #{enum_value.name}"
        print_directives(enum_value.directives)
        @out << "\n"
      end

      def print_input_object_type_definition(input_object_type)
        print_description(input_object_type)
        @out << "input #{input_object_type.name}"
        print_directives(input_object_type.directives)
        if !input_object_type.fields.empty?
          @out << " {\n"
          input_object_type.fields.each.with_index do |field, i|
            print_description(field, indent: "  ", first_in_block: i == 0)
            @out << "  "
            print_input_value_definition(field)
            @out << "\n"
          end
          @out << "}"
        end
      end

      def print_directive_definition(directive)
        print_description(directive)
        @out << "directive @#{directive.name}"

        if directive.arguments.any?
          print_arguments(directive.arguments)
        end

        if directive.repeatable
          @out << " repeatable"
        end

        @out << " on #{directive.locations.map(&:name).join(" | ")}"
      end

      def print_description(node, indent: "", first_in_block: true)
        return unless node.description

        @out << "\n" if indent != "" && !first_in_block
        @out << GraphQL::Language::BlockString.print(node.description, indent: indent)
      end

      def print_field_definitions(fields)
        @out << " {\n"
        fields.each.with_index do |field, i|
          print_description(field, indent: "  ", first_in_block: i == 0)
          @out << "  "
          print_field_definition(field)
          @out << "\n"
        end
        @out << "}"
      end

      def print_directives(directives)
        return if directives.empty?

        directives.each do |d|
          @out << " "
          print_directive(d)
        end
      end

      def print_selections(selections, indent: "")
        return if selections.empty?

        @out << " {\n"
        selections.each do |selection|
          print_node(selection, indent: indent + "  ")
          @out << "\n"
        end
        @out << "#{indent}}"
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
          @out << GraphQL::Language.serialize(node)
        when Array
          @out << "["
          node.each_with_index do |v, i|
            print_node(v)
            @out << ", " if i < node.length - 1
          end
          @out << "]"
        when Hash
          @out << "{"
          node.each_with_index do |(k, v), i|
            @out << "#{k}: "
            print_node(v)
            @out << ", " if i < node.length - 1
          end
          @out << "}"
        else
          @out << GraphQL::Language.serialize(node.to_s)
        end
      end
    end
  end
end
