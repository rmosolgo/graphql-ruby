module GraphQL
  class Schema
    # Restrict access to a {GraphQL::Schema} with a user-defined mask.
    #
    # The mask is object that responds to `#visible?(schema_member)`.
    #
    # When validating and executing a query, all access to schema members
    # should go through a warden. If you access the schema directly,
    # you may show a client something that it shouldn't be allowed to see.
    #
    # Masks can be provided in {Schema#execute} (or {Query#initialize}) with the `mask:` keyword.
    # @see [GraphQL::Schema::Mask] A built-in mask implementation.
    class Warden
      # @param schema [GraphQL::Schema]
      # @param mask [<#visible?(member)>] This object controls access to schema members
      def initialize(schema, mask)
        @mask = mask
        @schema = schema
      end

      # @return [Array<GraphQL::BaseType>] Visible types in the schema
      def types
        @schema.types.each_value.select { |t| visible?(t) }
      end

      # @return [GraphQL::BaseType, nil] The type named `type_name`, if it exists (else `nil`)
      def get_type(type_name)
        type_defn = @schema.types.fetch(type_name, nil)
        if type_defn && visible?(type_defn)
          type_defn
        else
          nil
        end
      end

      # @return [GraphQL::Field, nil] The field named `field_name` on `parent_type`, if it exists
      def get_field(parent_type, field_name)
        field_defn = @schema.get_field(parent_type, field_name)
        if field_defn && visible_field?(field_defn)
          field_defn
        else
          nil
        end
      end

      # @return [Array<GraphQL::BaseType>] The types which may be member of `type_defn`
      def possible_types(type_defn)
        @schema.possible_types(type_defn).select { |t| visible?(t) }
      end

      # @param type_defn [GraphQL::ObjectType, GraphQL::InterfaceType]
      # @return [Array<GraphQL::Field>] Fields on `type_defn`
      def fields(type_defn)
        type_defn.all_fields.select { |f| visible_field?(f) }
      end

      # @param argument_owner [GraphQL::Field, GraphQL::InputObjectType]
      # @return [Array<GraphQL::Argument>] Visible arguments on `argument_owner`
      def arguments(argument_owner)
        argument_owner.arguments.each_value.select do |arg_defn|
          visible?(arg_defn) && visible?(arg_defn.type.unwrap)
        end
      end

      # @return [Array<GraphQL::EnumType::EnumValue>] Visible members of `enum_defn`
      def enum_values(enum_defn)
        enum_defn.values.each_value.select { |enum_value_defn| visible?(enum_value_defn) }
      end

      # @return [Array<GraphQL::InterfaceType>] Visible interfaces implemented by `obj_type`
      def interfaces(obj_type)
        obj_type.interfaces.select { |t| visible?(t) }
      end

      private

      def visible_field?(field_defn)
        visible?(field_defn) && visible?(field_defn.type.unwrap)
      end

      def visible?(member)
        @mask.visible?(member)
      end
    end
  end
end
