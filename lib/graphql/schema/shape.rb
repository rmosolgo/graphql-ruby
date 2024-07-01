# frozen_string_literal: true

module GraphQL
  class Schema
    class Shape
      def initialize(query)
        @query = query
        @context = query.context
        @schema = query.schema
        @all_types = {}
        @all_types_loaded = false
        @unvisited_types = []
        @cached_visible = Hash.new { |h, k| h[k] = k.visible?(@context) }.compare_by_identity

        @cached_reachable = Hash.new do |h, type|
          h[type] = case type.kind.name
          when "UNION"
            possible_types(type).any?
          else
            true
          end
        end.compare_by_identity

        @cached_visible_fields = Hash.new { |h, field|
          h[field] = if @cached_visible[field] && (ret_type = field.type.unwrap) && @cached_visible[ret_type] && @cached_reachable[ret_type]
            add_type(ret_type)
            true
          else
            false
          end
        }.compare_by_identity
        # TODO don't I also need @cached_visible_args?
      end

      def type(type_name)
        if (loaded_t = @all_types[type_name])
          loaded_t
        else
          t = @schema.load_type(type_name, @context)
          if t.is_a?(Array)
            vis_t = nil
            t.each do |t_defn|
              if @cached_visible[t_defn]
                if vis_t.nil?
                  add_type(t_defn)
                  vis_t = t_defn
                else
                  raise_duplicate_definition(vis_t, t_defn)
                end
              end
            end
            vis_t
          else
            if t && @cached_visible[t]
              add_type(t)
              t
            else
              nil
            end
          end
        end
      end

      def field(owner, field_name)
        f = if owner.kind.fields? && (field = owner.get_field(field_name, @context, skip_visible: true))
          field
        elsif owner == query_root && (entry_point_field = @schema.introspection_system.entry_point(name: field_name))
          entry_point_field
        elsif (dynamic_field = @schema.introspection_system.dynamic_field(name: field_name))
          dynamic_field
        else
          nil
        end
        if f.is_a?(Array)
          visible_f = nil
          f.each do |f_defn|
            if @cached_visible_fields[f_defn]

              if visible_f.nil?
                visible_f = f_defn
              else
                raise_duplicate_definition(visible_f, f_defn)
              end
            end
          end
          visible_f
        else
          if f && @cached_visible_fields[f]
            f
          else
            nil
          end
        end
      end

      def fields(owner)
        non_duplicate_items(owner.all_field_definitions, @cached_visible_fields)
      end

      def arguments(owner)
        non_duplicate_items(owner.all_argument_definitions, @cached_visible)
      end

      def argument(owner, arg_name)
        # TODO this makes a Warden.visible_entry call down the stack
        # I need a non-Warden implementation
        arg = owner.get_argument(arg_name, @context, skip_visible: true)
        if arg.is_a?(Array)
          visible_arg = nil
          arg.each do |arg_defn|
            if @cached_visible[arg_defn]
              if arg_defn&.loads
                add_type(arg_defn.loads)
              end
              if visible_arg.nil?
                visible_arg = arg_defn
              else
                raise_duplicate_definition(visible_arg, arg_defn)
              end
            end
          end
          visible_arg
        else
          if arg && @cached_visible[arg]
            if arg&.loads
              add_type(arg.loads)
            end
            arg
          else
            nil
          end
        end
      end

      def possible_types(type)
        add_type(type)
        pt = case type.kind.name
        when "OBJECT"
          [type]
        when "INTERFACE"
          @schema.possible_types(type)
        when "UNION"
          type.type_memberships.select { |tm| @cached_visible[tm] && @cached_visible[tm.object_type] }.map!(&:object_type)
        end

        pt = pt.select { |t|  @cached_visible[t] ? (add_type(t); true) : false  }
        pt
      end

      def interfaces(obj_type)
        obj_type.interface_type_memberships.select { |itm| @cached_visible[itm] && @cached_visible[itm.abstract_type] }.map!(&:abstract_type)
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
        load_all_types
        @all_types.values
      end

      def enum_values(owner)
        add_type(owner)
        non_duplicate_items(owner.all_enum_value_definitions, @cached_visible)
      end

      def directive_exists?(dir_name)
        dir = @schema.directives[dir_name]
        dir && @cached_visible[dir]
      end

      def directives
        @schema.directives.each_value.select { |d| @cached_visible[d] }
      end

      def loadable?(t, _ctx)
        !@all_types[t.graphql_name] # TODO make sure t is not reachable but t is visible
      end

      def reachable_type?(t)
        true # TODO ...
      end

      private

      def add_type(t)
        if t && @cached_visible[t]
          n = t.graphql_name
          if prev_t = @all_types[n]
            if !prev_t.equal?(t)
              raise_duplicate_definition(prev_t, t)
            end
            false
          else
            if !t.respond_to?(:kind)
              binding.pry
            end
            @all_types[n] = t
            @unvisited_types << t
            true
          end
        else
          false
        end
      end

      def non_duplicate_items(definitions, visibility_cache)
        non_dups = []
        definitions.each do |defn|
          if visibility_cache[defn]
            if (dup_defn = non_dups.find { |d| d.graphql_name == defn.graphql_name })
              raise_duplicate_definition(dup_defn, defn)
            end
            non_dups << defn
          end
        end
        non_dups
      end

      def raise_duplicate_definition(first_defn, second_defn)
        raise DuplicateNamesError.new(duplicated_name: first_defn.path, duplicated_definition_1: first_defn.inspect, duplicated_definition_2: second_defn.inspect)
      end

      def load_all_types
        return if @all_types_loaded
        @all_types_loaded = true
        schema_types = @schema.types.values
        schema_types.compact! # TODO why is this necessary?!
        schema_types.flatten! # handle multiple defns
        schema_types.each { |t| add_type(t) }
        while t = @unvisited_types.pop
          # These have already been checked for `.visible?`
          visit_type(t)
        end
      end

      def visit_type(type, include_interface_possible_types: false)
        if type.kind.input_object?
          # recurse into visible arguments
          arguments(type).each do |argument|
            add_type(argument.type.unwrap)
          end
        elsif type.kind.union?
          # recurse into visible possible types
          possible_types(type).each do |possible_type|
            add_type(possible_type)
          end
        elsif type.kind.fields?
          if type.kind.object?
            # recurse into visible implemented interfaces
            interfaces(type).each do |interface|
              add_type(interface)
            end
          elsif include_interface_possible_types
            possible_types(type).each do |pt|
              add_type(interface)
            end
          end
          # Don't visit interface possible types -- it's not enough to justify visibility

          # recurse into visible fields
          t_f = fields(type)
          t_f.each do |field|
            field_type = field.type.unwrap
            # In this case, if it's an interface, we want to include
            # visit_type(unvisited_types, field_type, include_interface_possible_types: true)
            # TODO ^^ reimplement that
            add_type(field_type)
            # recurse into visible arguments
            arguments(field).each do |argument|
              add_type(argument.type.unwrap)
            end
          end
        end
      end
    end
  end
end
