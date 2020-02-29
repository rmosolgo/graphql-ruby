# frozen_string_literal: true
module GraphQL
  module Language
    # A custom printer used to print sanitized queries. It inlines provided variables
    # within the query for facilitate logging and analysis of queries.
    #
    # The printer returns `nil` if the query is invalid.
    #
    # Since the GraphQL Ruby AST for a GraphQL query doesnt contain any reference
    # on the type of fields or arguments, we have to track the current object, field
    # and input type while printing the query.
    #
    # @example Printing a scrubbed string
    #   printer = QueryPrinter.new(query)
    #   puts printer.sanitized_query_string
    #
    # @see {Query#sanitized_query_string}
    class SanitizedPrinter < GraphQL::Language::Printer

      REDACTED = "\"<REDACTED>\""

      def initialize(query)
        @query = query
        @current_type = nil
        @current_field = nil
        @current_input_type = nil
      end

      # @return [String, nil] A scrubbed query string, if the query was valid.
      def sanitized_query_string
        if query.valid?
          print(query.document)
        else
          nil
        end
      end

      def print_node(node, indent: "")
        if node.is_a?(String)
          type = @current_input_type.unwrap
          # Replace any strings that aren't IDs or Enum values with REDACTED
          if type.kind.enum? || type.graphql_name == "ID"
            super
          else
            REDACTED
          end
        elsif node.is_a?(Array)
          old_input_type = @current_input_type
          if @current_input_type && @current_input_type.list?
            @current_input_type = @current_input_type.of_type
            @current_input_type = @current_input_type.of_type if @current_input_type.non_null?
          end

          res = super
          @current_input_type = old_input_type
          res
        else
          super
        end
      end

      def print_argument(argument)
        arg_owner = @current_input_type || @current_directive || @current_field
        arg_def = arg_owner.arguments[argument.name]

        old_input_type = @current_input_type
        @current_input_type = arg_def.type.non_null? ? arg_def.type.of_type : arg_def.type
        res = super
        @current_input_type = old_input_type
        res
      end

      def print_list_type(list_type)
        old_input_type = @current_input_type
        @current_input_type = old_input_type.of_type
        res = super
        @current_input_type = old_input_type
        res
      end

      def print_variable_identifier(variable_id)
        variable_value = query.variables[variable_id.name]
        print_node(value_to_ast(variable_value, @current_input_type))
      end

      def print_field(field, indent: "")
        @current_field = query.schema.get_field(@current_type, field.name)
        old_type = @current_type
        @current_type = @current_field.type.unwrap
        res = super
        @current_type = old_type
        res
      end

      def print_inline_fragment(inline_fragment, indent: "")
        old_type = @current_type

        if inline_fragment.type
          @current_type = query.schema.types[inline_fragment.type.name]
        end

        res = super

        @current_type = old_type

        res
      end

      def print_fragment_definition(fragment_def, indent: "")
        old_type = @current_type
        @current_type = query.schema.types[fragment_def.type.name]

        res = super

        @current_type = old_type

        res
      end

      def print_directive(directive)
        @current_directive = query.schema.directives[directive.name]

        res = super

        @current_directive = nil
        res
      end

      # Print the operation definition but do not include the variable
      # definitions since we will inline them within the query
      def print_operation_definition(operation_definition, indent: "")
        old_type = @current_type
        @current_type = query.schema.public_send(operation_definition.operation_type)

        out = "#{indent}#{operation_definition.operation_type}".dup
        out << " #{operation_definition.name}" if operation_definition.name
        out << print_directives(operation_definition.directives)
        out << print_selections(operation_definition.selections, indent: indent)

        @current_type = old_type
        out
      end

      private

      def value_to_ast(value, type)
        type = type.of_type if type.non_null?

        if value.nil?
          return GraphQL::Language::Nodes::NullValue.new(name: "null")
        end

        case type.kind.name
        when "INPUT_OBJECT"
          value = if value.respond_to?(:to_unsafe_h)
            # for ActionController::Parameters
            value.to_unsafe_h
          else
            value.to_h
          end

          arguments = value.map do |key, val|
            sub_type = type.arguments[key.to_s].type

            GraphQL::Language::Nodes::Argument.new(
              name: key.to_s,
              value: value_to_ast(val, sub_type)
            )
          end
          GraphQL::Language::Nodes::InputObject.new(
            arguments: arguments
          )
        when "LIST"
          if value.respond_to?(:each)
            value.each { |v| value_to_ast(v, type.of_type) }
          else
            [value].each { |v| value_to_ast(v, type.of_type) }
          end
        when "ENUM"
          GraphQL::Language::Nodes::Enum.new(name: value)
        else
          value
        end
      end

      attr_reader :query
    end
  end
end
