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
        if preload
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

          profiles.each do |profile_name, example_ctx|
            example_ctx[:visibility_profile] = profile_name
            prof = profile_for(example_ctx, profile_name)
            prof.all_types # force loading
          end
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

      private

      def top_level_profile(refresh: false)
        if refresh
          @top_level_profile = nil
        end
        @top_level_profile ||= @schema.visibility_profile_class.new(context: Query::NullContext.instance, schema: @schema)
      end

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
