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
        @profiles = profiles
        @cached_profiles = {}
        @dynamic = dynamic
        @migration_errors = migration_errors
        if preload
          profiles.each do |profile_name, example_ctx|
            example_ctx[:visibility_profile] = profile_name
            prof = profile_for(example_ctx, profile_name)
            prof.all_types # force loading
          end
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
              @schema.visibility_profile_class.new(context: context, schema: @schema)
            elsif @profiles.any?
              raise ArgumentError, "#{@schema} expects a visibility profile, but `visibility_profile:` wasn't passed. Provide a `visibility_profile:` value or add `dynamic: true` to your visibility configuration."
            end
          elsif !@profiles.include?(visibility_profile)
            raise ArgumentError, "`#{visibility_profile.inspect}` isn't allowed for `visibility_profile:` (must be one of #{@profiles.keys.map(&:inspect).join(", ")}). Or, add `#{visibility_profile.inspect}` to the list of profiles in the schema definition."
          else
            @cached_profiles[visibility_profile] ||= @schema.visibility_profile_class.new(name: visibility_profile, context: context, schema: @schema)
          end
        else
          @schema.visibility_profile_class.new(context: context, schema: @schema)
        end
      end
    end
  end
end
