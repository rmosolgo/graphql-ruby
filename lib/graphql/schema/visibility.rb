# frozen_string_literal: true
require "graphql/schema/visibility/profile"
require "graphql/schema/visibility/migration"

module GraphQL
  class Schema
    # Use this plugin to make some parts of your schema hidden from some viewers.
    #
    class Visibility
      # @param schema [Class<GraphQL::Schema>]
      # @param profiles [Hash<Symbol => Hash>] A hash of `name => context` pairs for preloading visibility profiles
      # @param preload [Boolean] if `true`, load the default schema profile and all named profiles immediately (defaults to `true` for `Rails.env.production?`)
      # @param migration_errors [Boolean] if `true`, raise an error when `Visibility` and `Warden` return different results
      def self.use(schema, dynamic: false, profiles: EmptyObjects::EMPTY_HASH, preload: (defined?(Rails) ? Rails.env.production? : nil), migration_errors: false)
        schema.visibility = self.new(schema, dynamic: dynamic, preload: preload, profiles: profiles, migration_errors: migration_errors)
        if preload
          schema.visibility.preload
        end
      end

      def initialize(schema, dynamic:, preload:, profiles:, migration_errors:)
        @schema = schema
        schema.use_visibility_profile = true
        if migration_errors
          schema.visibility_profile_class = Migration
        end
        @preload = preload
        @profiles = profiles
        @cached_profiles = {}
        @dynamic = dynamic
        @migration_errors = migration_errors
        @top_level = TopLevel.new(@schema)
      end

      class TopLevel
        def initialize(schema)
          @schema = schema
          @loaded_all = false
          @interface_type_memberships = Hash.new { |h, interface_type| h[interface_type] = [] }.compare_by_identity
          @directives = []
          @types = {} # String => Module
          @references = Hash.new { |h, member| h[member] = [] }.compare_by_identity
        end

        def directives
          load_all
          @directives
        end

        def interface_type_memberships
          load_all
          @interface_type_memberships
        end

        def references
          load_all
          @references
        end

        def get_type(type_name)
          load_all
          @types[type_name]
        end

        private

        def load_all
          # TODO thread-safe
          @loaded_all ||= begin
            visit = Visit.new(@schema)

            visit.entry_point_types.each do |t|
              @references[t] << true
            end

            unions_for_references = []

            visit.visit_each do |member|
              if member.is_a?(Module)
                type_name = member.graphql_name
                if (prev_t = @types[type_name])
                  if prev_t.is_a?(Array)
                    prev_t << member
                  else
                    @types[type_name] = [member, prev_t]
                  end
                else
                  @types[member.graphql_name] = member
                end
                if member < GraphQL::Schema::Directive
                  @directives << member
                elsif member.respond_to?(:interface_type_memberships)
                  member.interface_type_memberships.each do |itm|
                    @references[itm.abstract_type] << member
                    @interface_type_memberships[itm.abstract_type] << itm
                  end
                elsif member < GraphQL::Schema::Union
                  unions_for_references << member
                end
              elsif member.is_a?(GraphQL::Schema::Argument)
                member.validate_default_value
                @references[member.type.unwrap] << member
              elsif member.is_a?(GraphQL::Schema::Field)
                @references[member.type.unwrap] << member
              end
              true
            end
            @interface_type_memberships.each do |int_type, type_memberships|
              referers = @references[int_type]
              type_memberships.each do |type_membership|
                implementor_type = type_membership.object_type
                @references[implementor_type].concat(referers)
              end
            end

            unions_for_references.each do |union_type|
              refs = @references[union_type]
              union_type.all_possible_types.each do |object_type|
                @references[object_type].concat(refs)
              end
            end
            true
          end
        end
      end

      class Visit
        def initialize(schema)
          @schema = schema
          @late_bound_types = nil
          @unvisited_types = nil
        end

        def entry_point_types
          ept = [
            @schema.query,
            @schema.mutation,
            @schema.subscription,
            *@schema.introspection_system.types.values,
            *@schema.introspection_system.entry_points.map { |ep| ep.type.unwrap },
            *@schema.orphan_types,
          ]
          ept.compact!
          ept
        end

        def visit_each
          @unvisited_types && raise("Can't call #visit_each twice on this Visit object")
          @unvisited_types = entry_point_types
          @late_bound_types = []
          visited_types = Set.new.compare_by_identity
          visited_directives = Set.new.compare_by_identity

          directives_to_visit = []

          @schema.directives.each_value { |dir_class|
            if visited_directives.add?(dir_class)
              yield(dir_class)
              dir_class.all_argument_definitions.each do |arg_defn|
                if yield(arg_defn)
                  directives_to_visit.concat(arg_defn.directives)
                  append_unvisited_type(dir_class, arg_defn.type.unwrap)
                end
              end
            end
          }

          while @unvisited_types.any? || @late_bound_types.any?
            while (type = @unvisited_types.pop)
              if visited_types.add?(type) && yield(type)
                directives_to_visit.concat(type.directives)
                case type.kind.name
                when "OBJECT", "INTERFACE"
                  type.interface_type_memberships.each do |itm|
                    append_unvisited_type(type, itm.abstract_type)
                  end
                  if type.kind.interface?
                    type.orphan_types.each do |orphan_type|
                      append_unvisited_type(type, orphan_type)
                    end
                  end

                  type.all_field_definitions.each do |field|
                    field.ensure_loaded
                    if yield(field)
                      directives_to_visit.concat(field.directives)
                      append_unvisited_type(type, field.type.unwrap)
                      field.all_argument_definitions.each do |argument|
                        if yield(argument)
                          directives_to_visit.concat(argument.directives)
                          append_unvisited_type(field, argument.type.unwrap)
                        end
                      end
                    end
                  end
                when "INPUT_OBJECT"
                  type.all_argument_definitions.each do |argument|
                    if yield(argument)
                      directives_to_visit.concat(argument.directives)
                      append_unvisited_type(type, argument.type.unwrap)
                    end
                  end
                when "UNION"
                  type.type_memberships.each do |tm|
                    append_unvisited_type(type, tm.object_type)
                  end
                when "ENUM"
                  type.all_enum_value_definitions.each do |val|
                    if yield(val)
                      directives_to_visit.concat(val.directives)
                    end
                  end
                when "SCALAR"
                  # pass -- nothing else to visit
                else
                  raise "Invariant: unhandled type kind: #{type.kind.inspect}"
                end
              end
            end

            directives_to_visit.each do |dir|
              dir_class = dir.class
              if visited_directives.add?(dir_class)
                yield(dir_class)
              end
            end

            missed_late_types_streak = 0
            while (owner, late_type = @late_bound_types.shift)
              if (late_type.is_a?(String) && (type = Member::BuildType.constantize(type))) ||
                  (late_type.is_a?(LateBoundType) && (type = visited_types.find { |t| t.graphql_name == late_type.graphql_name }))
                missed_late_types_streak = 0 # might succeed next round
                update_type_owner(owner, type)
                append_unvisited_type(owner, type)
              else
                # Didn't find it -- keep trying
                missed_late_types_streak += 1
                @late_bound_types << [owner, late_type]
                if missed_late_types_streak == @late_bound_types.size
                  raise UnresolvedLateBoundTypeError.new(type: late_type)
                end
              end
            end
          end
          nil
        end

        private

        def append_unvisited_type(owner, type)
          if type.is_a?(LateBoundType) || type.is_a?(String)
            @late_bound_types << [owner, type]
          else
            @unvisited_types << type
          end
        end

        def update_type_owner(owner, type)
          case owner
          when Module
            if owner.kind.union?
              owner.assign_type_membership_object_type(type)
            elsif type.kind.interface?
              new_interfaces = []
              owner.interfaces.each do |int_t|
                if int_t.is_a?(String) && int_t == type.graphql_name
                  new_interfaces << type
                elsif int_t.is_a?(LateBoundType) && int_t.graphql_name == type.graphql_name
                  new_interfaces << type
                else
                  # Don't re-add proper interface definitions,
                  # they were probably already added, maybe with options.
                end
              end
              owner.implements(*new_interfaces)
              new_interfaces.each do |int|
                pt = @possible_types[int] ||= []
                if !pt.include?(owner) && owner.is_a?(Class)
                  pt << owner
                end
                int.interfaces.each do |indirect_int|
                  if indirect_int.is_a?(LateBoundType) && (indirect_int_type = get_type(indirect_int.graphql_name))
                    update_type_owner(owner, indirect_int_type)
                  end
                end
              end
            end
          when GraphQL::Schema::Argument, GraphQL::Schema::Field
            orig_type = owner.type
            # Apply list/non-null wrapper as needed
            if orig_type.respond_to?(:of_type)
              transforms = []
              while (orig_type.respond_to?(:of_type))
                if orig_type.kind.non_null?
                  transforms << :to_non_null_type
                elsif orig_type.kind.list?
                  transforms << :to_list_type
                else
                  raise "Invariant: :of_type isn't non-null or list"
                end
                orig_type = orig_type.of_type
              end
              transforms.reverse_each { |t| type = type.public_send(t) }
            end
            owner.type = type
          else
            raise "Unexpected update: #{owner.inspect} #{type.inspect}"
          end
        end
      end

      def preload
        # Traverse the schema now (and in the *_configured hooks below)
        # To make sure things are loaded during boot
        @preloaded_types = Set.new
        types_to_visit = [
          @schema.query,
          @schema.mutation,
          @schema.subscription,
          *@schema.introspection_system.types.values,
          *@schema.introspection_system.entry_points.map { |ep| ep.type.unwrap },
          *@schema.orphan_types,
        ]
        # Root types may have been nil:
        types_to_visit.compact!
        ensure_all_loaded(types_to_visit)

        @profiles.each do |profile_name, example_ctx|
          example_ctx[:visibility_profile] = profile_name
          prof = profile_for(example_ctx, profile_name)
          prof.all_types # force loading
        end
      end

      # @api private
      def query_configured(query_type)
        if @preload
          ensure_all_loaded([query_type])
        end
      end

      # @api private
      def mutation_configured(mutation_type)
        if @preload
          ensure_all_loaded([mutation_type])
        end
      end

      # @api private
      def subscription_configured(subscription_type)
        if @preload
          ensure_all_loaded([subscription_type])
        end
      end

      # @api private
      def orphan_types_configured(orphan_types)
        if @preload
          ensure_all_loaded(orphan_types)
        end
      end

      # @api private
      def introspection_system_configured(introspection_system)
        if @preload
          introspection_types = [
            *@schema.introspection_system.types.values,
            *@schema.introspection_system.entry_points.map { |ep| ep.type.unwrap },
          ]
          ensure_all_loaded(introspection_types)
        end
      end

      # Make another Visibility for `schema` based on this one
      # @return [Visibility]
      # @api private
      def dup_for(other_schema)
        self.class.new(
          other_schema,
          dynamic: @dynamic,
          preload: @preload,
          profiles: @profiles,
          migration_errors: @migration_errors
        )
      end

      def migration_errors?
        @migration_errors
      end

      attr_reader :cached_profiles

      def profile_for(context, visibility_profile)
        if @profiles.any?
          if visibility_profile.nil?
            if @dynamic
              if context.is_a?(Query::NullContext)
                top_level_profile
              else
                @schema.visibility_profile_class.new(context: context, schema: @schema)
              end
            elsif @profiles.any?
              raise ArgumentError, "#{@schema} expects a visibility profile, but `visibility_profile:` wasn't passed. Provide a `visibility_profile:` value or add `dynamic: true` to your visibility configuration."
            end
          elsif !@profiles.include?(visibility_profile)
            raise ArgumentError, "`#{visibility_profile.inspect}` isn't allowed for `visibility_profile:` (must be one of #{@profiles.keys.map(&:inspect).join(", ")}). Or, add `#{visibility_profile.inspect}` to the list of profiles in the schema definition."
          else
            @cached_profiles[visibility_profile] ||= @schema.visibility_profile_class.new(name: visibility_profile, context: context, schema: @schema)
          end
        elsif context.is_a?(Query::NullContext)
          top_level_profile
        else
          @schema.visibility_profile_class.new(context: context, schema: @schema)
        end
      end

      attr_reader :top_level

      # @api private
      attr_reader :unfiltered_interface_type_memberships

      def top_level_profile(refresh: false)
        if refresh
          @top_level_profile = nil
        end
        @top_level_profile ||= @schema.visibility_profile_class.new(context: Query::NullContext.instance, schema: @schema)
      end

      private

      def ensure_all_loaded(types_to_visit)
        while (type = types_to_visit.shift)
          if type.kind.fields? && @preloaded_types.add?(type)
            type.all_field_definitions.each do |field_defn|
              field_defn.ensure_loaded
              types_to_visit << field_defn.type.unwrap
            end
          end
        end
        top_level_profile(refresh: true)
        nil
      end
    end
  end
end
