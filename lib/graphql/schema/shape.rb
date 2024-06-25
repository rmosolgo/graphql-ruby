# frozen_string_literal: true

module GraphQL
  class Schema
    class Shape
      def initialize(query)
        @query = query
        @context = query.context
        @schema = query.schema
        @all_types = Set.new.compare_by_identity
      end

      def type(type_name)
        # TODO filter
        @all_types.find { |t| t.graphql_name == t } || @schema.load_type(type_name, @context)
      end

      def field(owner, field_name)
        # TODO filter
        @all_types.add(owner)
        f = if owner.kind.fields? && (field = owner.get_field(field_name)) # TODO pass context
          field
        elsif owner == query_root && (entry_point_field = @schema.introspection_system.entry_point(name: field_name))
          entry_point_field
        elsif (dynamic_field = @schema.introspection_system.dynamic_field(name: field_name))
          dynamic_field
        else
          nil
        end
        f && @all_types.add(f.type.unwrap)
        f
      end

      def arguments(owner)
        # TODO filter
        owner.arguments.values
      end

      def argument(owner, arg_name)
        owner.get_argument(arg_name) # TODO filter
      end

      def possible_types(type)
        # TODO filter
        @all_types.add(type)
        pt = case type.kind.name
        when "OBJECT"
          [type]
        when "INTERFACE"
          @schema.possible_types(type)
        when "UNION"
          type.possible_types
        end
        @all_types.merge(pt)
        pt
      end

      def query_root
        t = @schema.query # TODO filter
        @all_types.add(t)
        t
      end

      def all_types
        @all_types
      end

      def enum_values(owner)
        @all_types.add(owner)
        owner.enum_values # TODO filter
      end
    end
  end
end
