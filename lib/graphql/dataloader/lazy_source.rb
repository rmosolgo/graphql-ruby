# frozen_string_literal: true
require "graphql/dataloader/source"

module GraphQL
  class Dataloader
    class LazySource < GraphQL::Dataloader::Source
      def initialize(phase, context)
        @context = context
        @phase = phase
      end

      def fetch(lazies)
        lazies.map do |l|
          @context.schema.sync_lazy(l)
        rescue StandardError => err
          err
        end
      end

      attr_reader :phase

      def defer?
        @phase == :field_resolve && dataloader.source_cache[self.class].any? { |k, v| v.phase == :object_wrap && v.pending? }
      end
    end
  end
end
