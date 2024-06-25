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
        t = @all_types.find { |t| t.graphql_name == t } || @schema.load_type(type_name, @context)
        if t&.visible?(@context)
          t
        else
          nil
        end
      end

      def field(owner, field_name)
        # TODO filter
        f = if owner.kind.fields? && (field = owner.get_field(field_name, @context)) # TODO pass context
          field
        elsif owner == query_root && (entry_point_field = @schema.introspection_system.entry_point(name: field_name))
          entry_point_field
        elsif (dynamic_field = @schema.introspection_system.dynamic_field(name: field_name))
          dynamic_field
        else
          nil
        end
        if f&.visible?(@context) && (ret_type = f.type.unwrap).visible?(@context)
          @all_types.add(owner)
          @all_types.add(ret_type)
          f
        else
          nil
        end
      end

      def fields(owner)
        # TODO filter
        owner.fields.values.select { |f| f.visible?(@context) }
      end

      def arguments(owner)
        # TODO filter
        owner.arguments.values.select { |a| a.visible?(@context) }
      end

      def argument(owner, arg_name)
        arg = owner.get_argument(arg_name) # TODO filter
        if arg&.visible?(@context)
          if arg&.loads
            @all_types.add(arg.loads)
          end
          arg
        else
          nil
        end
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

      def interfaces(obj_type)
        obj_type.interfaces # TODO filter
      end

      def query_root
        t = @schema.query # TODO filter
        @all_types.add(t)
        t
      end

      def mutation_root
        t = @schema.mutation # TODO filter
        @all_types.add(t)
        t
      end

      def subscription_root
        t = @schema.subscription # TODO filter
        @all_types.add(t)
        t
      end

      def all_types
        @all_types
      end

      def enum_values(owner)
        @all_types.add(owner)
        # TODO filter
        owner.enum_values.select { |v| v.visible?(@context) }
      end

      def directive_exists?(dir_name)
        @schema.directives[dir_name]&.visible?(@context)
      end

      def directives
        @schema.directives.each_value.select { |d| d.visible?(@context) }
      end

      def loadable?(t, _ctx)
        !@all_types.include?(t) # TODO make sure t is not reachable but t is visible
      end

      def reachable_type?(t)
        true # TODO ...
      end
    end
  end
end
