# frozen_string_literal: true

require 'set'

module GraphQL
  class Schema
    # Restrict access to a {GraphQL::Schema} with a user-defined filter.
    #
    # When validating and executing a query, all access to schema members
    # should go through a warden. If you access the schema directly,
    # you may show a client something that it shouldn't be allowed to see.
    #
    # @example Hidding private fields
    #   private_members = -> (member, ctx) { member.metadata[:private] }
    #   result = Schema.execute(query_string, except: private_members)
    #
    # @example Custom filter implementation
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
      # @param filter [<#call(member)>] Objects are hidden when `.call(member, ctx)` returns true
      # @param context [GraphQL::Query::Context]
      # @param schema [GraphQL::Schema]
      # @param deep_check [Boolean]
      def initialize(filter, context:, schema:)
        @schema = schema
        @context = context
        @visibility_cache = read_through { |m| filter.call(m, @context) }
      end

      # @return [Array<GraphQL::BaseType>] Visible types in the schema
      def types
        @types ||= @schema.types.each_value.select { |t| visible_type?(t) }
      end

      # @return [GraphQL::BaseType, nil] The type named `type_name`, if it exists (else `nil`)
      def get_type(type_name)
        @visible_types ||= read_through do |name|
          type_defn = @schema.types.fetch(name, nil)
          if type_defn && visible_type?(type_defn)
            type_defn
          else
            nil
          end
        end

        @visible_types[type_name]
      end

      # @return [Array<GraphQL::BaseType>] Visible and reachable types in the schema
      def reachable_types
        @reachable_types ||= reachable_type_set.to_a
      end

      # @return Boolean True if the type is visible and reachable in the schema
      def reachable_type?(type_name)
        type = get_type(type_name)
        type && reachable_type_set.include?(type)
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
        @visible_possible_types ||= read_through { |type_defn| @schema.possible_types(type_defn, @context).select { |t| visible_type?(t) } }
        @visible_possible_types[type_defn]
      end

      # @param type_defn [GraphQL::ObjectType, GraphQL::InterfaceType]
      # @return [Array<GraphQL::Field>] Fields on `type_defn`
      def fields(type_defn)
        @visible_fields ||= read_through { |t| @schema.get_fields(t).each_value.select { |f| visible_field?(f) } }
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

      def union_memberships(obj_type)
        @unions ||= read_through { |obj_type| @schema.union_memberships(obj_type).select { |u| visible?(u) } }
        @unions[obj_type]
      end

      def visible_field?(field_defn)
        visible?(field_defn) && visible_type?(field_defn.type.unwrap)
      end

      def visible_type?(type_defn)
        return false unless visible?(type_defn)
        return true if root_type?(type_defn)
        return true if type_defn.introspection?

        if type_defn.kind.union?
          visible_possible_types?(type_defn) && (referenced?(type_defn) || orphan_type?(type_defn))
        elsif type_defn.kind.interface?
          visible_possible_types?(type_defn)
        else
          referenced?(type_defn) || visible_abstract_type?(type_defn)
        end
      end

      def root_type?(type_defn)
        @schema.root_types.include?(type_defn)
      end

      def referenced?(type_defn)
        members = @schema.references_to(type_defn.unwrap.name)
        members.any? { |m| visible?(m) }
      end

      def orphan_type?(type_defn)
        @schema.orphan_types.include?(type_defn)
      end

      def visible_abstract_type?(type_defn)
        type_defn.kind.object? && (
            interfaces(type_defn).any? ||
            union_memberships(type_defn).any?
          )
      end

      def visible_possible_types?(type_defn)
        @schema.possible_types(type_defn, @context).any? { |t| visible_type?(t) }
      end

      def visible?(member)
        @visibility_cache[member]
      end

      def read_through
        Hash.new { |h, k| h[k] = yield(k) }
      end

      def reachable_type_set
        return @reachable_type_set if defined?(@reachable_type_set)

        @reachable_type_set = Set.new

        unvisited_types = []
        ['query', 'mutation', 'subscription'].each do |op_name|
          root_type = root_type_for_operation(op_name)
          unvisited_types << root_type if root_type
        end
        unvisited_types.concat(@schema.introspection_system.object_types)
        @schema.orphan_types.each do |orphan_type|
          unvisited_types << orphan_type.graphql_definition if get_type(orphan_type.graphql_name)
        end

        until unvisited_types.empty?
          type = unvisited_types.pop
          if @reachable_type_set.add?(type)
            if type.kind.input_object?
              # recurse into visible arguments
              arguments(type).each do |argument|
                argument_type = argument.type.unwrap
                unvisited_types << argument_type
              end
            elsif type.kind.union?
              # recurse into visible possible types
              possible_types(type).each do |possible_type|
                unvisited_types << possible_type
              end
            elsif type.kind.fields?
              if type.kind.interface?
                # recurse into visible possible types
                possible_types(type).each do |possible_type|
                  unvisited_types << possible_type
                end
              elsif type.kind.object?
                # recurse into visible implemented interfaces
                interfaces(type).each do |interface|
                  unvisited_types << interface
                end
              end

              # recurse into visible fields
              fields(type).each do |field|
                field_type = field.type.unwrap
                unvisited_types << field_type
                # recurse into visible arguments
                arguments(field).each do |argument|
                  argument_type = argument.type.unwrap
                  unvisited_types << argument_type
                end
              end
            end
          end
        end

        @reachable_type_set
      end
    end
  end
end
