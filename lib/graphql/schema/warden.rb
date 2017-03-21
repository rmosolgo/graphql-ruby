# frozen_string_literal: true
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
    #
    # @example Hidding private fields
    #   private_members = -> (member, ctx) { member.metadata[:private] }
    #   result = Schema.execute(query_string, except: private_members)
    #
    # @example Custom mask implementation
    #   # It must respond to `#call(member)`.
    #   class MissingRequiredFlags
    #     def initialize(user)
    #       @user = user
    #     end
    #
    #     # Return `false` if any required flags are missing
    #     def call(member, ctx)
    #       member.metadata[:required_flags].any? do |flag|
    #         !@user.has_flag?(flag)
    #       end
    #     end
    #   end
    #
    #   # Then, use the custom filter in query:
    #   missing_required_flags = MissingRequiredFlags.new(current_user)
    #
    #   # This query can only access members which match the user's flags
    #   result = Schema.execute(query_string, except: missing_required_flags)
    #
    # @api private
    class Warden
      # @param mask [<#call(member)>] Objects are hidden when `.call(member, ctx)` returns true
      # @param context [GraphQL::Query::Context]
      # @param schema [GraphQL::Schema]
      # @param deep_check [Boolean]
      def initialize(mask, context:, schema:)
        @schema = schema
        @visibility_cache = read_through { |m| !mask.call(m, context) }
      end

      # @return [Array<GraphQL::BaseType>] Visible types in the schema
      def types
        @types ||= @schema.types.each_value.select { |t| visible?(t) }
      end

      # @return [GraphQL::BaseType, nil] The type named `type_name`, if it exists (else `nil`)
      def get_type(type_name)
        @visible_types ||= read_through do |name|
          type_defn = @schema.types.fetch(name, nil)
          if type_defn && visible?(type_defn)
            type_defn
          else
            nil
          end
        end

        @visible_types[type_name]
      end

      # @return [GraphQL::Field, nil] The field named `field_name` on `parent_type`, if it exists
      def get_field(parent_type, field_name)

        @visible_parent_fields ||= read_through do |type|
          read_through do |f_name|
            field_defn = @schema.get_field(type, f_name)
            if field_defn && visible_field?(field_defn)
              field_defn
            else
              nil
            end
          end
        end

        @visible_parent_fields[parent_type][field_name]
      end

      # @return [Array<GraphQL::BaseType>] The types which may be member of `type_defn`
      def possible_types(type_defn)
        @visible_possible_types ||= read_through { |type_defn| @schema.possible_types(type_defn).select { |t| visible?(t) } }
        @visible_possible_types[type_defn]
      end

      # @param type_defn [GraphQL::ObjectType, GraphQL::InterfaceType]
      # @return [Array<GraphQL::Field>] Fields on `type_defn`
      def fields(type_defn)
        @visible_fields ||= read_through { |t| t.all_fields.select { |f| visible_field?(f) } }
        @visible_fields[type_defn]
      end

      # @param argument_owner [GraphQL::Field, GraphQL::InputObjectType]
      # @return [Array<GraphQL::Argument>] Visible arguments on `argument_owner`
      def arguments(argument_owner)
        @visible_arguments ||= read_through { |o| o.arguments.each_value.select { |a| visible_field?(a) } }
        @visible_arguments[argument_owner]
      end

      # @return [Array<GraphQL::EnumType::EnumValue>] Visible members of `enum_defn`
      def enum_values(enum_defn)
        @visible_enum_values ||= read_through { |e| e.values.each_value.select { |enum_value_defn| visible?(enum_value_defn) } }
        @visible_enum_values[enum_defn]
      end

      # @return [Array<GraphQL::InterfaceType>] Visible interfaces implemented by `obj_type`
      def interfaces(obj_type)
        @visible_interfaces ||= read_through { |t| t.interfaces.select { |i| visible?(i) } }
        @visible_interfaces[obj_type]
      end

      def directives
        @schema.directives.each_value.select { |d| visible?(d) }
      end

      def root_type_for_operation(op_name)
        root_type = @schema.root_type_for_operation(op_name)
        if root_type && visible?(root_type)
          root_type
        else
          nil
        end
      end

      private

      def visible_field?(field_defn)
        visible?(field_defn) && visible?(field_defn.type.unwrap)
      end

      def visible?(member)
        @visibility_cache[member]
      end

      def read_through
        Hash.new { |h, k| h[k] = yield(k) }
      end
    end
  end
end
