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
      # @param schema [GraphQL::Schema]
      def print_schema(schema)
        whitelist = ->(m) { IS_USER_DEFINED_MEMBER.call(m) }
        print_filtered_schema(schema, whitelist)
      end

      # Return the GraphQL schema string for the introspection type system
      def print_introspection_schema
        query_root = ObjectType.define do
          name "Root"
        end
        schema = GraphQL::Schema.define(query: query_root)
        whitelist = IS_INTROSPECTION_MEMBER
        print_filtered_schema(schema, whitelist)
      end

      private

      BUILTIN_DIRECTIVE_NAMES = Set.new(['skip', 'include', 'deprecated'])
      BUILTIN_SCALARS = Set.new(["String", "Boolean", "Int", "Float", "ID"])

      # By default, these are included in a schema printout
      IS_USER_DEFINED_MEMBER = ->(member) {
        case member
        when GraphQL::ObjectType, GraphQL::EnumType
          !member.name.start_with?("__")
        when GraphQL::Directive
          !BUILTIN_DIRECTIVE_NAMES.include?(member.name)
        when GraphQL::ScalarType
          !BUILTIN_SCALARS.include?(member.name)
        else
          true
        end
      }

      # These are included in an introspection schema printout
      IS_INTROSPECTION_MEMBER = ->(member) {
        case member
        when GraphQL::ScalarType
          !BUILTIN_SCALARS.include?(member.name)
        else
          !IS_USER_DEFINED_MEMBER.call(member)
        end
      }


      private_constant :BUILTIN_DIRECTIVE_NAMES, :BUILTIN_SCALARS, :IS_INTROSPECTION_MEMBER, :IS_USER_DEFINED_MEMBER

      def print_filtered_schema(schema, whitelist)
        directive_definitions = schema
          .directives
          .values
          .select { |directive| whitelist.call(directive) }
          .map { |directive| print_directive(directive) }

        type_definitions = schema
          .types
          .values
          .select { |type| whitelist.call(type) }
          .sort_by(&:name)
          .map { |type| print_type(type) }

        [print_schema_definition(schema)].compact
                                         .concat(directive_definitions)
                                         .concat(type_definitions).join("\n\n")
      end

      def print_schema_definition(schema)
        if (schema.query.nil? || schema.query.name == 'Query') &&
           (schema.mutation.nil? || schema.mutation.name == 'Mutation') &&
           (schema.subscription.nil? || schema.subscription.name == 'Subscription')
          return
        end

        operations = [:query, :mutation, :subscription].map do |operation_type|
          object_type = schema.public_send(operation_type)
          "  #{operation_type}: #{object_type.name}\n" if object_type
        end.compact.join
        "schema {\n#{operations}}"
      end

      def print_type(type)
        TypeKindPrinters::STRATEGIES.fetch(type.kind).print(type)
      end

      def print_directive(directive)
        TypeKindPrinters::DirectivePrinter.print(directive)
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
          def print_args(field, indentation = '')
            return if field.arguments.empty?

            field_arguments = field.arguments.values

            if field_arguments.all?{ |arg| !arg.description }
              return "(#{field_arguments.map{ |arg| print_input_value(arg) }.join(", ")})"
            end

            out = "(\n".dup
            out << field_arguments.map.with_index{ |arg, i|
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
          def print_fields(type)
            type.all_fields.map.with_index { |field, i|
              "#{print_description(field, '  ', i == 0)}"\
              "  #{field.name}#{print_args(field, '  ')}: #{field.type}#{print_deprecated(field)}"
            }.join("\n")
          end
        end

        class DirectivePrinter
          extend ArgsPrinter
          extend DescriptionPrinter
          def self.print(directive)
            "#{print_description(directive)}"\
            "directive @#{directive.name}#{print_args(directive)} "\
            "on #{directive.locations.join(' | ')}"
          end
        end

        class ScalarPrinter
          extend DescriptionPrinter
          def self.print(type)
            "#{print_description(type)}"\
            "scalar #{type.name}"
          end
        end

        class ObjectPrinter
          extend FieldPrinter
          extend DescriptionPrinter
          def self.print(type)
            if type.interfaces.any?
              implementations = " implements #{type.interfaces.map(&:to_s).join(", ")}"
            else
              implementations = nil
            end

            "#{print_description(type)}"\
            "type #{type.name}#{implementations} {\n"\
            "#{print_fields(type)}\n"\
            "}"
          end
        end

        class InterfacePrinter
          extend FieldPrinter
          extend DescriptionPrinter
          def self.print(type)
            "#{print_description(type)}"\
            "interface #{type.name} {\n#{print_fields(type)}\n}"
          end
        end

        class UnionPrinter
          extend DescriptionPrinter
          def self.print(type)
            "#{print_description(type)}"\
            "union #{type.name} = #{type.possible_types.map(&:to_s).join(" | ")}"
          end
        end

        class EnumPrinter
          extend DeprecatedPrinter
          extend DescriptionPrinter
          def self.print(type)
            values = type.values.values.map{ |v| "  #{v.name}#{print_deprecated(v)}" }.join("\n")
            values = type.values.values.map.with_index { |v, i|
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
          def self.print(type)
            fields = type.input_fields.values.map.with_index{ |field, i|
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
