# frozen_string_literal: true
module GraphQL
  class Schema
    # Used to convert your {GraphQL::Schema} to a GraphQL schema string
    #
    # @example print your schema to standard output
    #   MySchema = GraphQL::Schema.define(query: QueryType)
    #   puts GraphQL::Schema::Printer.print_schema(MySchema)
    #
    module Printer
      extend self

      # Return a GraphQL schema string for the defined types in the schema
      # @param context [Hash]
      # @param only [<#call(member, ctx)>]
      # @param except [<#call(member, ctx)>]
      # @param schema [GraphQL::Schema]
      def print_schema(schema, context: nil, only: nil, except: nil)
        blacklist = if only
          ->(m, ctx) { !(IS_USER_DEFINED_MEMBER.call(m) && only.call(m, ctx)) }
        elsif except
          ->(m, ctx) { !IS_USER_DEFINED_MEMBER.call(m) || except.call(m, ctx) }
        else
          ->(m, ctx) { !IS_USER_DEFINED_MEMBER.call(m) }
        end

        warden = GraphQL::Schema::Warden.new(blacklist, schema: schema, context: context)

        print_filtered_schema(schema, warden: warden)
      end

      # Return the GraphQL schema string for the introspection type system
      def print_introspection_schema
        query_root = ObjectType.define(name: "Root")
        schema = GraphQL::Schema.define(query: query_root)
        blacklist = ->(m, ctx) { m == query_root }

        warden = GraphQL::Schema::Warden.new(blacklist, schema: schema, context: nil)

        print_filtered_schema(schema, warden: warden)
      end

      private

      BUILTIN_DIRECTIVE_NAMES = Set.new(['skip', 'include', 'deprecated'])

      BUILTIN_SCALARS = [
        GraphQL::STRING_TYPE,
        GraphQL::BOOLEAN_TYPE,
        GraphQL::INT_TYPE,
        GraphQL::FLOAT_TYPE,
        GraphQL::ID_TYPE,
      ]

      # By default, these are included in a schema printout
      IS_USER_DEFINED_MEMBER = ->(member) {
        case member
        when GraphQL::BaseType
          !member.name.start_with?("__")
        when GraphQL::Directive
          !BUILTIN_DIRECTIVE_NAMES.include?(member.name)
        else
          true
        end
      }

      private_constant :BUILTIN_DIRECTIVE_NAMES, :BUILTIN_SCALARS, :IS_USER_DEFINED_MEMBER

      def print_filtered_schema(schema, warden:)
        directive_definitions = warden.directives.map { |directive| print_directive(warden, directive) }

        printable_types = warden.types - BUILTIN_SCALARS

        type_definitions = printable_types
          .sort_by(&:name)
          .map { |type| print_type(warden, type) }

        [print_schema_definition(warden, schema)].compact
                                         .concat(directive_definitions)
                                         .concat(type_definitions).join("\n\n")
      end

      def print_schema_definition(warden, schema)
        if (schema.query.nil? || schema.query.name == 'Query') &&
           (schema.mutation.nil? || schema.mutation.name == 'Mutation') &&
           (schema.subscription.nil? || schema.subscription.name == 'Subscription')
          return
        end

        operations = [:query, :mutation, :subscription].map do |operation_type|
          object_type = schema.public_send(operation_type)
          # Special treatment for the introspection schema, which prints `{ query: "Root" }`
          if object_type && (warden.get_type(object_type.name) || (object_type.name == "Root" && schema.query == object_type))
            "  #{operation_type}: #{object_type.name}\n"
          else
            nil
          end
        end.compact.join
        "schema {\n#{operations}}"
      end

      def print_type(warden, type)
        TypeKindPrinters::STRATEGIES.fetch(type.kind).print(warden, type)
      end

      def print_directive(warden, directive)
        TypeKindPrinters::DirectivePrinter.print(warden, directive)
      end

      module TypeKindPrinters
        module DeprecatedPrinter
          def print_deprecated(field_or_enum_value)
            return unless field_or_enum_value.deprecation_reason

            case field_or_enum_value.deprecation_reason
            when nil
              ''
            when '', GraphQL::Directive::DEFAULT_DEPRECATION_REASON
              ' @deprecated'
            else
              " @deprecated(reason: #{field_or_enum_value.deprecation_reason.to_s.inspect})"
            end
          end
        end

        module DescriptionPrinter
          def print_description(definition, indentation='', first_in_block=true)
            return '' unless definition.description

            description = indentation != '' && !first_in_block ? "\n".dup : "".dup
            description << GraphQL::Language::Comments.commentize(definition.description, indent: indentation)
          end
        end

        module ArgsPrinter
          include DescriptionPrinter
          def print_args(warden, field, indentation = '')
            arguments = warden.arguments(field)
            return if arguments.empty?

            if arguments.all?{ |arg| !arg.description }
              return "(#{arguments.map{ |arg| print_input_value(arg) }.join(", ")})"
            end

            out = "(\n".dup
            out << arguments.map.with_index{ |arg, i|
              "#{print_description(arg, "  #{indentation}", i == 0)}  #{indentation}"\
              "#{print_input_value(arg)}"
            }.join("\n")
            out << "\n#{indentation})"
          end

          def print_input_value(arg)
            if arg.default_value?
              default_string = " = #{print_value(arg.default_value, arg.type)}"
            else
              default_string = nil
            end

            "#{arg.name}: #{arg.type.to_s}#{default_string}"
          end

          def print_value(value, type)
            case type
            when FLOAT_TYPE
              return 'null' if value.nil?
              value.to_f.inspect
            when INT_TYPE
              return 'null' if value.nil?
              value.to_i.inspect
            when BOOLEAN_TYPE
              return 'null' if value.nil?
              (!!value).inspect
            when ScalarType, ID_TYPE, STRING_TYPE
              return 'null' if value.nil?
              value.to_s.inspect
            when EnumType
              return 'null' if value.nil?
              type.coerce_result(value)
            when InputObjectType
              return 'null' if value.nil?
              fields = value.to_h.map{ |field_name, field_value|
                field_type = type.input_fields.fetch(field_name.to_s).type
                "#{field_name}: #{print_value(field_value, field_type)}"
              }.join(", ")
              "{#{fields}}"
            when NonNullType
              print_value(value, type.of_type)
            when ListType
              return 'null' if value.nil?
              "[#{value.to_a.map{ |v| print_value(v, type.of_type) }.join(", ")}]"
            else
              raise NotImplementedError, "Unexpected value type #{type.inspect}"
            end
          end
        end

        module FieldPrinter
          include DeprecatedPrinter
          include ArgsPrinter
          include DescriptionPrinter
          def print_fields(warden, type)
            fields = warden.fields(type)
            fields.map.with_index { |field, i|
              "#{print_description(field, '  ', i == 0)}"\
              "  #{field.name}#{print_args(warden, field, '  ')}: #{field.type}#{print_deprecated(field)}"
            }.join("\n")
          end
        end

        class DirectivePrinter
          extend ArgsPrinter
          extend DescriptionPrinter
          def self.print(warden, directive)
            "#{print_description(directive)}"\
            "directive @#{directive.name}#{print_args(warden, directive)} "\
            "on #{directive.locations.join(' | ')}"
          end
        end

        class ScalarPrinter
          extend DescriptionPrinter
          def self.print(warden, type)
            "#{print_description(type)}"\
            "scalar #{type.name}"
          end
        end

        class ObjectPrinter
          extend FieldPrinter
          extend DescriptionPrinter
          def self.print(warden, type)
            interfaces = warden.interfaces(type)
            if interfaces.any?
              implementations = " implements #{interfaces.map(&:to_s).join(", ")}"
            else
              implementations = nil
            end

            "#{print_description(type)}"\
            "type #{type.name}#{implementations} {\n"\
            "#{print_fields(warden, type)}\n"\
            "}"
          end
        end

        class InterfacePrinter
          extend FieldPrinter
          extend DescriptionPrinter
          def self.print(warden, type)
            "#{print_description(type)}"\
            "interface #{type.name} {\n#{print_fields(warden, type)}\n}"
          end
        end

        class UnionPrinter
          extend DescriptionPrinter
          def self.print(warden, type)
            possible_types = warden.possible_types(type)
            "#{print_description(type)}"\
            "union #{type.name} = #{possible_types.map(&:to_s).join(" | ")}"
          end
        end

        class EnumPrinter
          extend DeprecatedPrinter
          extend DescriptionPrinter
          def self.print(warden, type)
            enum_values = warden.enum_values(type)

            values = enum_values.map.with_index { |v, i|
              "#{print_description(v, '  ', i == 0)}"\
              "  #{v.name}#{print_deprecated(v)}"
            }.join("\n")

            "#{print_description(type)}"\
            "enum #{type.name} {\n#{values}\n}"
          end
        end

        class InputObjectPrinter
          extend FieldPrinter
          extend DescriptionPrinter
          def self.print(warden, type)
            arguments = warden.arguments(type)
            fields = arguments.map.with_index{ |field, i|
              "#{print_description(field, "  ", i == 0)}"\
              "  #{print_input_value(field)}"
            }.join("\n")
            "#{print_description(type)}"\
            "input #{type.name} {\n#{fields}\n}"
          end
        end

        STRATEGIES = {
          GraphQL::TypeKinds::SCALAR =>       ScalarPrinter,
          GraphQL::TypeKinds::OBJECT =>       ObjectPrinter,
          GraphQL::TypeKinds::INTERFACE =>    InterfacePrinter,
          GraphQL::TypeKinds::UNION =>        UnionPrinter,
          GraphQL::TypeKinds::ENUM =>         EnumPrinter,
          GraphQL::TypeKinds::INPUT_OBJECT => InputObjectPrinter,
        }
      end
      private_constant :TypeKindPrinters
    end
  end
end
