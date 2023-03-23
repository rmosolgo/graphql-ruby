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

        def append(other)
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
        @out = TruncatableBuffer.new(truncate_size: truncate_size)
        print_node(node, indent: indent)
        @out.to_string
      rescue TruncatableBuffer::TruncateSizeReached
        @out.to_string << OMISSION
      end

      protected

      def print_document(document)
        document.definitions.each_with_index do |d, i|
          print_node(d)
          @out.append("\n\n") if i < document.definitions.size - 1
        end
      end

      def print_argument(argument)
        @out.append("#{argument.name}: ")
        print_node(argument.value)
      end

      def print_input_object(input_object)
        @out.append("{")
        input_object.arguments.each_with_index do |a, i|
          print_argument(a)
          @out.append(", ") if i < input_object.arguments.size - 1
        end
        @out.append("}")
      end

      def print_directive(directive)
        @out.append("@#{directive.name}")

        if directive.arguments.any?
          @out.append("(")
          directive.arguments.each_with_index do |a, i|
            print_argument(a)
            @out.append(", ") if i < directive.arguments.size - 1
          end
          @out.append(")")
        end
      end

      def print_enum(enum)
        @out.append(enum.name)
      end

      def print_null_value
        @out.append("null")
      end

      def print_field(field, indent: "")
        @out.append(indent)
        @out.append("#{field.alias}: ") if field.alias
        @out.append(field.name)
        if field.arguments.any?
          @out.append("(")
          field.arguments.each_with_index do |a, i|
            print_argument(a)
            @out.append(", ") if i < field.arguments.size - 1
          end
          @out.append(")")
        end
        print_directives(field.directives)
        print_selections(field.selections, indent: indent)
      end

      def print_fragment_definition(fragment_def, indent: "")
        @out.append("#{indent}fragment #{fragment_def.name}")
        if fragment_def.type
          @out.append(" on ")
          print_node(fragment_def.type)
        end
        print_directives(fragment_def.directives)
        print_selections(fragment_def.selections, indent: indent)
      end

      def print_fragment_spread(fragment_spread, indent: "")
        @out.append("#{indent}...#{fragment_spread.name}")
        print_directives(fragment_spread.directives)
      end

      def print_inline_fragment(inline_fragment, indent: "")
        @out.append("#{indent}...")
        if inline_fragment.type
          @out.append(" on ")
          print_node(inline_fragment.type)
        end
        print_directives(inline_fragment.directives)
        print_selections(inline_fragment.selections, indent: indent)
      end

      def print_list_type(list_type)
        @out.append("[")
        print_node(list_type.of_type)
        @out.append("]")
      end

      def print_non_null_type(non_null_type)
        print_node(non_null_type.of_type)
        @out.append("!")
      end

      def print_operation_definition(operation_definition, indent: "")
        @out.append("#{indent}#{operation_definition.operation_type}")
        @out.append(" #{operation_definition.name}") if operation_definition.name

        if operation_definition.variables.any?
          @out.append("(")
          operation_definition.variables.each_with_index do |v, i|
            print_variable_definition(v)
            @out.append(", ") if i < operation_definition.variables.size - 1
          end
          @out.append(")")
        end

        print_directives(operation_definition.directives)
        print_selections(operation_definition.selections, indent: indent)
      end

      def print_type_name(type_name)
        @out.append(type_name.name)
      end

      def print_variable_definition(variable_definition)
        @out.append("$#{variable_definition.name}: ")
        print_node(variable_definition.type)
        unless variable_definition.default_value.nil?
          @out.append(" = ")
          print_node(variable_definition.default_value)
        end
      end

      def print_variable_identifier(variable_identifier)
        @out.append("$#{variable_identifier.name}")
      end


      def print_schema_definition(schema)
        has_conventional_names =
          (schema.query.nil? || schema.query == 'Query') &&
          (schema.mutation.nil? || schema.mutation == 'Mutation') &&
          (schema.subscription.nil? || schema.subscription == 'Subscription')

        if has_conventional_names && schema.directives.empty?
          return
        end

        @out.append("schema")

        if schema.directives.any?
          schema.directives.each do |dir|
            @out.append("\n  ")
            print_node(dir)
          end

          if !has_conventional_names
            @out.append("\n")
          end
        end

        if !has_conventional_names
          if schema.directives.empty?
            @out.append(" ")
          end
          @out.append("{\n")
          @out.append("  query: #{schema.query}\n") if schema.query
          @out.append("  mutation: #{schema.mutation}\n") if schema.mutation
          @out.append("  subscription: #{schema.subscription}\n") if schema.subscription
          @out.append("}")
        end
      end

      def print_scalar_type_definition(scalar_type)
        print_description(scalar_type)
        @out.append("scalar #{scalar_type.name}")
        print_directives(scalar_type.directives)
      end

      def print_object_type_definition(object_type)
        print_description(object_type)
        @out.append("type #{object_type.name}")
        print_implements(object_type) unless object_type.interfaces.empty?
        print_directives(object_type.directives)
        print_field_definitions(object_type.fields)
      end

      def print_implements(type)
        @out.append(" implements #{type.interfaces.map(&:name).join(" & ")}")
      end

      def print_input_value_definition(input_value)
        @out.append("#{input_value.name}: ")
        print_node(input_value.type)
        unless input_value.default_value.nil?
          @out.append(" = ")
          print_node(input_value.default_value)
        end
        print_directives(input_value.directives)
      end

      def print_arguments(arguments, indent: "")
        if arguments.all? { |arg| !arg.description }
          @out.append("(")
          arguments.each_with_index do |arg, i|
            print_input_value_definition(arg)
            @out.append(", ") if i < arguments.size - 1
          end
          @out.append(")")
          return
        end

        @out.append("(\n")
        arguments.each_with_index do |arg, i|
          print_description(arg, indent: "  " + indent, first_in_block: i == 0)
          @out.append("  #{@indent}")
          print_input_value_definition(arg)
          @out.append("\n") if i < arguments.size - 1
        end
        @out.append("\n#{@indent})")
      end

      def print_field_definition(field)
        @out.append(field.name)
        unless field.arguments.empty?
          print_arguments(field.arguments, indent: "  ")
        end
        @out.append(": ")
        print_node(field.type)
        print_directives(field.directives)
      end

      def print_interface_type_definition(interface_type)
        print_description(interface_type)
        @out.append("interface #{interface_type.name}")
        print_implements(interface_type) if interface_type.interfaces.any?
        print_directives(interface_type.directives)
        print_field_definitions(interface_type.fields)
      end

      def print_union_type_definition(union_type)
        print_description(union_type)
        @out.append("union #{union_type.name}")
        print_directives(union_type.directives)
        @out.append(" = #{union_type.types.map(&:name).join(" | ")}")
      end

      def print_enum_type_definition(enum_type)
        print_description(enum_type)
        @out.append("enum #{enum_type.name}")
        print_directives(enum_type.directives)
        @out.append(" {\n")
        enum_type.values.each.with_index do |value, i|
          print_description(value, indent: "  ", first_in_block: i == 0)
          print_enum_value_definition(value)
        end
        @out.append("}")
      end

      def print_enum_value_definition(enum_value)
        @out.append("  #{enum_value.name}")
        print_directives(enum_value.directives)
        @out.append("\n")
      end

      def print_input_object_type_definition(input_object_type)
        print_description(input_object_type)
        @out.append("input #{input_object_type.name}")
        print_directives(input_object_type.directives)
        if !input_object_type.fields.empty?
          @out.append(" {\n")
          input_object_type.fields.each.with_index do |field, i|
            print_description(field, indent: "  ", first_in_block: i == 0)
            @out.append("  ")
            print_input_value_definition(field)
            @out.append("\n")
          end
          @out.append("}")
        end
      end

      def print_directive_definition(directive)
        print_description(directive)
        @out.append("directive @#{directive.name}")

        if directive.arguments.any?
          print_arguments(directive.arguments)
        end

        if directive.repeatable
          @out.append(" repeatable")
        end

        @out.append(" on #{directive.locations.map(&:name).join(" | ")}")
      end

      def print_description(node, indent: "", first_in_block: true)
        return unless node.description

        @out.append("\n") if indent != "" && !first_in_block
        @out.append(GraphQL::Language::BlockString.print(node.description, indent: indent))
      end

      def print_field_definitions(fields)
        @out.append(" {\n")
        fields.each.with_index do |field, i|
          print_description(field, indent: "  ", first_in_block: i == 0)
          @out.append("  ")
          print_field_definition(field)
          @out.append("\n")
        end
        @out.append("}")
      end

      def print_directives(directives)
        return if directives.empty?

        directives.each do |d|
          @out.append(" ")
          print_directive(d)
        end
      end

      def print_selections(selections, indent: "")
        return if selections.empty?

        @out.append(" {\n")
        selections.each do |selection|
          print_node(selection, indent: indent + "  ")
          @out.append("\n")
        end
        @out.append("#{indent}}")
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
          @out.append(GraphQL::Language.serialize(node))
        when Array
          @out.append("[")
          node.each_with_index do |v, i|
            print_node(v)
            @out.append(", ") if i < node.length - 1
          end
          @out.append("]")
        when Hash
          @out.append("{")
          node.each_with_index do |(k, v), i|
            @out.append("#{k}: ")
            print_node(v)
            @out.append(", ") if i < node.length - 1
          end
          @out.append("}")
        else
          @out.append(GraphQL::Language.serialize(node.to_s))
        end
      end
    end
  end
end
