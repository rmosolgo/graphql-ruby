# frozen_string_literal: true

module GraphQL
  class Schema
    # This class filters the types, fields, arguments, enum values, and directives in a schema
    # based on the given `context`.
    #
    # It's like {Warden}, but has some differences:
    #
    # - It doesn't use {Schema}'s top-level caches (eg {Schema.references_to}, {Schema.possible_types}, {Schema.types})
    # - It doesn't hide Interface or Union types when all their possible types are hidden. (Instead, those types should implement `.visible?` to hide in that case.)
    # - It checks `.visible?` on root introspection types
    #
    # In the future, {Subset} will support lazy-loading types as needed during execution and multi-request caching of subsets.
    #
    # @see Schema::TypesMigration for a helper class in adopting this filter
    class Subset
      # @return [Schema::Subset]
      def self.from_context(ctx, schema)
        if ctx.respond_to?(:types) && (types = ctx.types).is_a?(self)
          types
        else
          # TODO use a cached instance from the schema
          self.new(context: ctx, schema: schema)
        end
      end

      def initialize(context:, schema:)
        @context = context
        @schema = schema
        @all_types = {}
        @all_types_loaded = false
        @unvisited_types = []
        @referenced_types = Hash.new { |h, type_defn| h[type_defn] = [] }.compare_by_identity
        @cached_directives = {}
        @all_directives = nil
        @cached_visible = Hash.new { |h, member|
          h[member] = @schema.visible?(member, @context)
        }.compare_by_identity

        @cached_visible_fields = Hash.new { |h, owner|
          h[owner] = Hash.new do |h2, field|
            h2[field] = if @cached_visible[field] &&
                (ret_type = field.type.unwrap) &&
                @cached_visible[ret_type] &&
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

        @cached_parent_fields = Hash.new do |h, type|
          h[type] = Hash.new do |h2, field_name|
            h2[field_name] = type.get_field(field_name, @context)
          end
        end.compare_by_identity

        @cached_parent_arguments = Hash.new do |h, arg_owner|
          h[arg_owner] = Hash.new do |h2, arg_name|
            h2[arg_name] = arg_owner.get_argument(arg_name, @context)
          end
        end.compare_by_identity

        @cached_possible_types = Hash.new do |h, type|
          h[type] = case type.kind.name
          when "INTERFACE"
            load_all_types
            pts = []
            @unfiltered_interface_type_memberships[type].each { |itm|
              if @cached_visible[itm] && (ot = itm.object_type) && @cached_visible[ot] && referenced?(ot)
                pts << ot
              end
            }
            pts
          when "UNION"
            pts = []
            type.type_memberships.each { |tm|
              if @cached_visible[tm] &&
                  (ot = tm.object_type) &&
                  @cached_visible[ot] &&
                  referenced?(ot)
                pts << ot
              end
            }
            pts
          when "OBJECT"
            load_all_types
            if @all_types[type.graphql_name] == type
              [type]
            else
              EmptyObjects::EMPTY_ARRAY
            end
          else
            GraphQL::EmptyObjects::EMPTY_ARRAY
          end
        end.compare_by_identity

        @cached_enum_values = Hash.new do |h, enum_t|
          values = non_duplicate_items(enum_t.all_enum_value_definitions, @cached_visible)
          if values.size == 0
            raise GraphQL::Schema::Enum::MissingValuesError.new(enum_t)
          end
          h[enum_t] = values
        end.compare_by_identity

        @cached_fields = Hash.new do |h, owner|
          h[owner] = non_duplicate_items(owner.all_field_definitions, @cached_visible_fields[owner])
        end.compare_by_identity

        @cached_arguments = Hash.new do |h, owner|
          h[owner] = non_duplicate_items(owner.all_argument_definitions, @cached_visible_arguments)
        end.compare_by_identity
      end

      def field_on_visible_interface?(field, owner)
        ints = owner.interface_type_memberships.map(&:abstract_type)
        field_name = field.graphql_name
        filtered_ints = interfaces(owner)
        any_interface_has_field = false
        any_interface_has_visible_field = false
        ints.each do |int_t|
          if (_int_f_defn = @cached_parent_fields[int_t][field_name])
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
        f = if owner.kind.fields? && (field = @cached_parent_fields[owner][field_name])
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
        @cached_fields[owner]
      end

      def arguments(owner)
        @cached_arguments[owner]
      end

      def argument(owner, arg_name)
        arg = @cached_parent_arguments[owner][arg_name]
        if arg.is_a?(Array)
          visible_arg = nil
          arg.each do |arg_defn|
            if @cached_visible_arguments[arg_defn]
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
            arg
          else
            nil
          end
        end
      end

      def possible_types(type)
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
        load_all_types
        @all_types.values
      end

      def all_types_h
        load_all_types
        @all_types
      end

      def enum_values(owner)
        @cached_enum_values[owner]
      end

      def directive_exists?(dir_name)
        if (dir = @schema.directives[dir_name]) && @cached_visible[dir]
          !!dir
        else
          load_all_types
          !!@cached_directives[dir_name]
        end
      end

      def directives
        @all_directives ||= begin
          load_all_types
          dirs = []
          @schema.directives.each do |name, dir_defn|
            if !@cached_directives[name] && @cached_visible[dir_defn]
              dirs << dir_defn
            end
          end
          dirs.concat(@cached_directives.values)
        end
      end

      def loadable?(t, _ctx)
        !@all_types[t.graphql_name] && @cached_visible[t]
      end

      def loaded_types
        @all_types.values
      end

      def reachable_type?(name)
        load_all_types
        !!@all_types[name]
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
        @referenced_types[t].any? { |reference| (reference == true) || @cached_visible[reference] }
      end

      def load_all_types
        return if @all_types_loaded
        @all_types_loaded = true
        entry_point_types = [
          query_root,
          mutation_root,
          subscription_root,
          *@schema.introspection_system.types.values,
        ]

        # Don't include any orphan_types whose interfaces aren't visible.
        @schema.orphan_types.each do |orphan_type|
          if @cached_visible[orphan_type] &&
            orphan_type.interface_type_memberships.any? { |tm| @cached_visible[tm] && @cached_visible[tm.abstract_type] }
            entry_point_types << orphan_type
          end
        end

        @schema.directives.each do |_dir_name, dir_class|
          if @cached_visible[dir_class]
            arguments(dir_class).each do |arg|
              entry_point_types << arg.type.unwrap
            end
          end
        end

        entry_point_types.compact! # TODO why is this necessary?!
        entry_point_types.flatten! # handle multiple defns
        entry_point_types.each { |t| add_type(t, true) }

        @unfiltered_interface_type_memberships = Hash.new { |h, k| h[k] = [] }.compare_by_identity
        @add_possible_types = Set.new

        while @unvisited_types.any?
          while t = @unvisited_types.pop
            # These have already been checked for `.visible?`
            visit_type(t)
          end
          @add_possible_types.each do |int_t|
            itms = @unfiltered_interface_type_memberships[int_t]
            itms.each do |itm|
              if @cached_visible[itm] && (obj_type = itm.object_type) && @cached_visible[obj_type]
                add_type(obj_type, itm)
              end
            end
          end
          @add_possible_types.clear
        end

        @all_types.delete_if { |type_name, type_defn| !referenced?(type_defn) }
        nil
      end

      def visit_type(type)
        visit_directives(type)
        case type.kind.name
        when "OBJECT", "INTERFACE"
          if type.kind.object?
            type.interface_type_memberships.each do |itm|
              @unfiltered_interface_type_memberships[itm.abstract_type] << itm
            end
            # recurse into visible implemented interfaces
            interfaces(type).each do |interface|
              add_type(interface, type)
            end
          else
            type.orphan_types.each { |t| add_type(t, type)}
          end

          # recurse into visible fields
          t_f = type.all_field_definitions
          t_f.each do |field|
            if @cached_visible[field]
              visit_directives(field)
              field_type = field.type.unwrap
              if field_type.kind.interface?
                @add_possible_types.add(field_type)
              end
              add_type(field_type, field)

              # recurse into visible arguments
              arguments(field).each do |argument|
                visit_directives(argument)
                add_type(argument.type.unwrap, argument)
              end
            end
          end
        when "INPUT_OBJECT"
          # recurse into visible arguments
          arguments(type).each do |argument|
            visit_directives(argument)
            add_type(argument.type.unwrap, argument)
          end
        when "UNION"
          # recurse into visible possible types
          type.type_memberships.each do |tm|
            if @cached_visible[tm]
              obj_t = tm.object_type
              if obj_t.is_a?(String)
                obj_t = Member::BuildType.constantize(obj_t)
                tm.object_type = obj_t
              end
              if @cached_visible[obj_t]
                add_type(obj_t, tm)
              end
            end
          end
        when "ENUM"
          enum_values(type).each do |val|
            visit_directives(val)
          end
        when "SCALAR"
          # pass
        end
      end

      def visit_directives(member)
        member.directives.each { |dir|
          dir_class = dir.class
          if @cached_visible[dir_class]
            dir_name = dir_class.graphql_name
            if (existing_dir = @cached_directives[dir_name])
              if existing_dir != dir_class
                raise ArgumentError, "Two directives for `@#{dir_name}`: #{existing_dir}, #{dir.class}"
              end
            else
              @cached_directives[dir.graphql_name] = dir_class
            end
          end
        }
      end
    end
  end
end
