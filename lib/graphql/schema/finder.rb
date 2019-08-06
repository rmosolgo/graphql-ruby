# frozen_string_literal: true

module GraphQL
  class Schema
    # Find schema members using string paths
    #
    # @example Finding object types
    #   MySchema.find("SomeObjectType")
    #
    # @example Finding fields
    #   MySchema.find("SomeObjectType.myField")
    #
    # @example Finding arguments
    #   MySchema.find("SomeObjectType.myField.anArgument")
    #
    # @example Finding directives
    #   MySchema.find("@include")
    #
    class Finder
      class MemberNotFoundError < ArgumentError; end

      def initialize(schema)
        @schema = schema
      end

      def find(path)
        path = path.split(".")
        type_or_directive = path.shift

        if type_or_directive.start_with?("@")
          directive = schema.directives[type_or_directive[1..-1]]

          if directive.nil?
            raise MemberNotFoundError, "Could not find directive `#{type_or_directive}` in schema."
          end

          return directive if path.empty?

          find_in_directive(directive, path: path)
        else
          type = schema.types[type_or_directive]

          if type.nil?
            raise MemberNotFoundError, "Could not find type `#{type_or_directive}` in schema."
          end

          return type if path.empty?

          find_in_type(type, path: path)
        end
      end

      private

      attr_reader :schema

      def find_in_directive(directive, path:)
        argument_name = path.shift
        argument = directive.arguments[argument_name]

        if argument.nil?
          raise MemberNotFoundError, "Could not find argument `#{argument_name}` on directive #{directive}."
        end

        argument
      end

      def find_in_type(type, path:)
        case type
        when GraphQL::ObjectType
          find_in_fields_type(type, kind: "object", path: path)
        when GraphQL::InterfaceType
          find_in_fields_type(type, kind: "interface", path: path)
        when GraphQL::InputObjectType
          find_in_input_object(type, path: path)
        when GraphQL::UnionType
          # Error out if path that was provided is too long
          # i.e UnionType.PossibleType.aField
          # Use PossibleType.aField instead.
          if invalid = path.first
            raise MemberNotFoundError, "Cannot select union possible type `#{invalid}`. Select the type directly instead."
          end
        when GraphQL::EnumType
          find_in_enum_type(type, path: path)
        end
      end

      def find_in_fields_type(type, kind:, path:)
        field_name = path.shift
        field = schema.get_field(type, field_name)

        if field.nil?
          raise MemberNotFoundError, "Could not find field `#{field_name}` on #{kind} type `#{type}`."
        end

        return field if path.empty?

        find_in_field(field, path: path)
      end

      def find_in_field(field, path:)
        argument_name = path.shift
        argument = field.arguments[argument_name]

        if argument.nil?
          raise MemberNotFoundError, "Could not find argument `#{argument_name}` on field `#{field.name}`."
        end

        # Error out if path that was provided is too long
        # i.e Type.field.argument.somethingBad
        if invalid = path.first
          raise MemberNotFoundError, "Cannot select member `#{invalid}` on a field."
        end

        argument
      end

      def find_in_input_object(input_object, path:)
        field_name = path.shift
        input_field = input_object.input_fields[field_name]

        if input_field.nil?
          raise MemberNotFoundError, "Could not find input field `#{field_name}` on input object type `#{input_object}`."
        end

        # Error out if path that was provided is too long
        # i.e InputType.inputField.bad
        if invalid = path.first
          raise MemberNotFoundError, "Cannot select member `#{invalid}` on an input field."
        end

        input_field
      end

      def find_in_enum_type(enum_type, path:)
        value_name = path.shift
        enum_value = enum_type.values[value_name]

        if enum_value.nil?
          raise MemberNotFoundError, "Could not find enum value `#{value_name}` on enum type `#{enum_type}`."
        end

        # Error out if path that was provided is too long
        # i.e Enum.VALUE.wat
        if invalid = path.first
          raise MemberNotFoundError, "Cannot select member `#{invalid}` on an enum value."
        end

        enum_value
      end
    end
  end
end
