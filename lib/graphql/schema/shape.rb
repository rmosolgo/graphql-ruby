# frozen_string_literal: true

module GraphQL
  class Schema
    class Shape
      def initialize(query)
        @query = query
        @context = query.context
        @schema = query.schema
        @all_types = Set.new.compare_by_identity
        @all_types_loaded = false
      end

      def type(type_name)
        # TODO filter
        t = @all_types.find { |t| t.graphql_name == t } || @schema.load_type(type_name, @context)
        if t&.visible?(@context)
          # TODO add type?
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
          add_type(owner)
          add_type(ret_type)
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
            add_type(arg.loads)
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
        pt.each { |t| add_type(t) }
        pt
      end

      def interfaces(obj_type)
        obj_type.interfaces # TODO filter
      end

      def query_root
        t = @schema.query # TODO filter
        add_type(t)
        t
      end

      def mutation_root
        t = @schema.mutation # TODO filter
        add_type(t)
        t
      end

      def subscription_root
        t = @schema.subscription # TODO filter
        add_type(t)
        t
      end

      def all_types
        if !@all_types_loaded
          @schema.types.each_value { |t| add_type(t) }
          @all_types_loaded = true
        end
        @all_types
      end

      def enum_values(owner)
        add_type(owner)
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

      private

      def add_type(t)
        t && @all_types.add(t)
      end
    end
  end
end
