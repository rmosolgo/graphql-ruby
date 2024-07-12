# frozen_string_literal: true

module GraphQL
  class Schema
    class Subset
      def initialize(query)
        @query = query
        @context = query.context
        @schema = query.schema
        @all_types = {}
        @all_types_loaded = false
        @unvisited_types = []
        @referenced_types = Hash.new { |h, type_defn| h[type_defn] = [] }.compare_by_identity
        @cached_possible_types = nil
        @cached_visible = Hash.new { |h, member|
          h[member] = @schema.visible?(member, @context)
        }.compare_by_identity

        @cached_visible_fields = Hash.new { |h, owner|
          h[owner] = Hash.new do |h2, field|
            h2[field] = if @cached_visible[field] &&
                (ret_type = field.type.unwrap) &&
                @cached_visible[ret_type] &&
                reachable_type?(ret_type.graphql_name) &&
                (owner == field.owner || (!owner.kind.object?) || field_on_visible_interface?(field, owner))

              if !field.introspection?
                # The problem is that some introspection fields may have references
                # to non-custom introspection types.
                # If those were added here, they'd cause a DuplicateNamesError.
                # This is basically a bug -- those fields _should_ reference the custom types.
                add_type(ret_type, field)
              end
              true
            else
              false
            end
          end.compare_by_identity
        }.compare_by_identity

        @cached_visible_arguments = Hash.new do |h, arg|
          h[arg] = if @cached_visible[arg] && (arg_type = arg.type.unwrap) && @cached_visible[arg_type]
            add_type(arg_type, arg)
            true
          else
            false
          end
        end.compare_by_identity

        @unfiltered_pt = Hash.new do |hash, type|
          hash[type] = @schema.possible_types(type)
        end.compare_by_identity
      end

      def field_on_visible_interface?(field, owner)
        ints = owner.interface_type_memberships.map(&:abstract_type)
        field_name = field.graphql_name
        filtered_ints = interfaces(owner)
        any_interface_has_field = false
        any_interface_has_visible_field = false
        ints.each do |int_t|
          if (_int_f_defn = int_t.get_field(field_name, @context))
            any_interface_has_field = true

            if filtered_ints.include?(int_t) # TODO cycles, or maybe not necessary since previously checked? && @cached_visible_fields[owner][field]
              any_interface_has_visible_field = true
              break
            end
          end
        end

        if any_interface_has_field
          any_interface_has_visible_field
        else
          true
        end
      end

      def type(type_name)
        t = if (loaded_t = @all_types[type_name])
          loaded_t
       elsif !@all_types_loaded
         load_all_types
          @all_types[type_name]
        end

        if t
          if t.is_a?(Array)
            vis_t = nil
            t.each do |t_defn|
              if @cached_visible[t_defn]
                if vis_t.nil?
                  vis_t = t_defn
                else
                  raise_duplicate_definition(vis_t, t_defn)
                end
              end
            end
            vis_t
          else
            if t && @cached_visible[t]
              t
            else
              nil
            end
          end
        end
      end

      def field(owner, field_name)
        f = if owner.kind.fields? && (field = owner.get_field(field_name, @context))
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
            if @cached_visible_fields[owner][f_defn]

              if visible_f.nil?
                visible_f = f_defn
              else
                raise_duplicate_definition(visible_f, f_defn)
              end
            end
          end
          visible_f
        else
          if f && @cached_visible_fields[owner][f]
            f
          else
            nil
          end
        end
      end

      def fields(owner)
        non_duplicate_items(owner.all_field_definitions, @cached_visible_fields[owner])
      end

      def arguments(owner)
        non_duplicate_items(owner.all_argument_definitions, @cached_visible_arguments)
      end

      def argument(owner, arg_name)
        # TODO this makes a Warden.visible_entry call down the stack
        # I need a non-Warden implementation
        arg = owner.get_argument(arg_name, @context)
        if arg.is_a?(Array)
          visible_arg = nil
          arg.each do |arg_defn|
            if @cached_visible_arguments[arg_defn]
              if arg_defn&.loads
                add_type(arg_defn.loads, arg_defn)
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
          if arg && @cached_visible_arguments[arg]
            if arg&.loads
              add_type(arg.loads, arg)
            end
            arg
          else
            nil
          end
        end
      end

      def possible_types(type)
        @cached_possible_types ||= Hash.new do |h, type|
          pt = case type.kind.name
          when "INTERFACE"
            # TODO this requires the global map
            @unfiltered_pt[type]
          when "UNION"
            type.type_memberships.select { |tm| @cached_visible[tm] && @cached_visible[tm.object_type] }.map!(&:object_type)
          else
            [type]
          end

          # TODO use `select!` when possible, skip it for `[type]`
          h[type] = pt.select { |t|
            @cached_visible[t] && referenced?(t)
          }
        end.compare_by_identity
        @cached_possible_types[type]
      end

      def interfaces(obj_or_int_type)
        ints = obj_or_int_type.interface_type_memberships
          .select { |itm| @cached_visible[itm] && @cached_visible[itm.abstract_type] }
          .map!(&:abstract_type)
        ints.uniq! # Remove any duplicate interfaces implemented via other interfaces
        ints
      end

      def query_root
        add_if_visible(@schema.query)
      end

      def mutation_root
        add_if_visible(@schema.mutation)
      end

      def subscription_root
        add_if_visible(@schema.subscription)
      end

      def all_types
        @all_types_filtered ||= begin
          load_all_types
          at = []
          @all_types.each do |_name, type_defn|
            if possible_types(type_defn).any? || referenced?(type_defn)
              at << type_defn
            end
          end
          at
        end
      end

      def enum_values(owner)
        values = non_duplicate_items(owner.all_enum_value_definitions, @cached_visible)
        if values.size == 0
          raise GraphQL::Schema::Enum::MissingValuesError.new(owner)
        end
        values
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

      # TODO rename this to indicate that it is called with a typename
      def reachable_type?(type_name)
        load_all_types
        !!((t = @all_types[type_name]) && referenced?(t))
      end

      def loaded_types
        @all_types.values
      end

      private

      def add_if_visible(t)
        (t && @cached_visible[t]) ? (add_type(t, true); t) : nil
      end

      def add_type(t, by_member)
        if t && @cached_visible[t]
          n = t.graphql_name
          if (prev_t = @all_types[n])
            if !prev_t.equal?(t)
              raise_duplicate_definition(prev_t, t)
            end
            false
          else
            @referenced_types[t] << by_member
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

      def referenced?(t)
        load_all_types
        res = if @referenced_types[t].any? { |member| (member == true) || @cached_visible[member] }
          if t.kind.abstract?
            possible_types(t).any?
          else
            true
          end
        end
        res
      end

      def load_all_types
        return if @all_types_loaded
        @all_types_loaded = true
        schema_types = [
          query_root,
          mutation_root,
          subscription_root,
          *@schema.introspection_system.types.values,
        ]

        # Don't include any orphan_types whose interfaces aren't visible.
        @schema.orphan_types.each do |orphan_type|
          if @cached_visible[orphan_type] &&
            orphan_type.interface_type_memberships.any? { |tm| @cached_visible[tm] && @cached_visible[tm.abstract_type] }
            schema_types << orphan_type
          end
        end
        schema_types.compact! # TODO why is this necessary?!
        schema_types.flatten! # handle multiple defns
        schema_types.each { |t| add_type(t, true) }

        while t = @unvisited_types.pop
          # These have already been checked for `.visible?`
          visit_type(t)
        end

        @all_types.delete_if { |type_name, type_defn| !referenced?(type_defn) }
        nil
      end

      def visit_type(type)
        if type.kind.input_object?
          # recurse into visible arguments
          arguments(type).each do |argument|
            add_type(argument.type.unwrap, argument)
          end
        elsif type.kind.union?
          # recurse into visible possible types
          type.type_memberships.each do |tm|
            if @cached_visible[tm] && @cached_visible[tm.object_type]
              add_type(tm.object_type, tm)
            end
          end
        elsif type.kind.fields?
          if type.kind.object?
            # recurse into visible implemented interfaces
            interfaces(type).each do |interface|
              add_type(interface, type)
            end
          end

          # recurse into visible fields
          t_f = type.all_field_definitions
          t_f.each do |field|
            if @cached_visible[field]
              field_type = field.type.unwrap
              if field_type.kind.interface?
                pt = @unfiltered_pt[field_type]
                pt.each do |obj_type|
                  if @cached_visible[obj_type] &&
                      (tm = obj_type.interface_type_memberships.find { |tm| tm.abstract_type == field_type }) &&
                      @cached_visible[tm]
                    add_type(obj_type, tm)
                  end
                end
              end
              add_type(field_type, field)

              # recurse into visible arguments
              arguments(field).each do |argument|
                add_type(argument.type.unwrap, argument)
              end
            end
          end
        end
      end
    end
  end
end
