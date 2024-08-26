# frozen_string_literal: true
require "graphql/schema/visibility/subset"
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
      def self.use(schema, dynamic: false, profiles: EmptyObjects::EMPTY_ARRAY, preload: (defined?(Rails) ? Rails.env.production? : nil), migration_errors: false)
        schema.visibility = self.new(schema, dynamic: dynamic, preload: preload, profiles: profiles,)
        schema.use_schema_visibility = true
        if migration_errors
          schema.subset_class = Migration
        end
      end

      def initialize(schema, dynamic:, preload:, profiles:)
        @schema = schema
        @profiles = profiles
        @cached_profiles = {}
        @dynamic = dynamic

        if preload
          profiles.each do |profile_name, example_ctx|
            example_ctx ||= { visibility_profile: profile_name }
            prof = profile_for(example_ctx, profile_name)
            prof.all_types # force loading
          end
        end
      end

      attr_reader :cached_profiles

      def profile_for(context, visibility_profile)
        if @profiles.any?
          if visibility_profile.nil?
            if @dynamic
              Subset.new(context: context, schema: @schema)
            elsif @profiles.any?
              raise ArgumentError, "#{@schema} expects a visibility profile, but `visibility_profile:` wasn't passed. Provide a `visibility_profile:` value or add `dynamic: true` to your visibility configuration."
            end
          elsif !@profiles.include?(visibility_profile)
            raise ArgumentError, "`#{visibility_profile.inspect}` isn't allowed for `visibility_profile:` (must be one of #{@profiles.keys.map(&:inspect).join(", ")}). Or, add `#{visibility_profile.inspect}` to the list of profiles in the schema definition."
          else
            @cached_profiles[visibility_profile] ||= Subset.new(name: visibility_profile, context: context, schema: @schema)
          end
        else
          Subset.new(context: context, schema: @schema)
        end
      end

      module TypeIntegration
        def self.included(child_cls)
          child_cls.extend(ClassMethods)
        end

        module ClassMethods
          def visible_in(profiles = NOT_CONFIGURED)
            if NOT_CONFIGURED.equal?(profiles)
              @visible_in
            else
              @visible_in = Array(profiles)
            end
          end

          # TODO visible?

          def inherited(child_cls)
            super
            if visible_in
              child_cls.visible_in(visible_in)
            else
              child_cls.visible_in(nil)
            end
          end
        end
      end
      module FieldIntegration
        def self.included(child_cls)
          child_cls.extend(ClassMethods)
        end

        module ClassMethods
          def visible_in(visible_in = NOT_CONFIGURED)
            if NOT_CONFIGURED.equal?(visible_in)
              @visible_in
            else
              @visible_in = Array(visible_in)
            end
          end
        end
        def initialize(*args, visible_in: nil, **kwargs, &block)
          @visible_in = visible_in ? Array(visible_in) : nil
          super(*args, **kwargs, &block)
        end

        def visible?(context)
          v_i = @visible_in || self.class.visible_in
          if v_i
            v_p = context.respond_to?(:query) ? context.query.visibility_profile : context[:visibility_profile]
            super && v_i.include?(v_p)
          else
            super
          end
        end
      end
    end
  end
end
