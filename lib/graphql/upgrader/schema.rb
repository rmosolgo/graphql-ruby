# frozen_string_literal: true

module GraphQL
  module Upgrader
    class Schema
      def initialize(schema)
        GraphQL::Deprecation.warn "#{self.class} will be removed from GraphQL-Ruby 2.0 (but there's no point in using it after you've transformed your code, anyways)"
        @schema = schema
      end

      def upgrade
        transformable = schema.dup

        transformable.sub!(
          /([a-zA-Z_0-9]*) = GraphQL::Schema\.define do/, 'class \1 < GraphQL::Schema'
        )

        transformable.sub!(
          /object_from_id ->\s?\((.*)\) do/, 'def self.object_from_id(\1)'
        )

        transformable.sub!(
          /resolve_type ->\s?\((.*)\) do/, 'def self.resolve_type(\1)'
        )

        transformable.sub!(
          /id_from_object ->\s?\((.*)\) do/, 'def self.id_from_object(\1)'
        )

        transformable
      end

      private

      attr_reader :schema
    end
  end
end
