# frozen_string_literal: true

module GraphQL
  module Tracing
    # This implementation forwards events to ActiveSupport::Notifications
    # with a `graphql.` prefix.
    #
    module ActiveSupportNotificationsTracing
      # A cache of frequently-used keys to avoid needless string allocations
      KEYS = {
        "lex" => "graphql.lex",
        "parse" => "graphql.parse",
        "validate" => "graphql.validate",
        "analyze_multiplex" => "graphql.analyze_multiplex",
        "analyze_query" => "graphql.analyze_query",
        "execute_query" => "graphql.execute_query",
        "execute_query_lazy" => "graphql.execute_query_lazy",
        "execute_field" => "graphql.execute_field",
        "execute_field_lazy" => "graphql.execute_field_lazy",
      }

      def self.trace(key, metadata)
        prefixed_key = KEYS[key] || "graphql.#{key}"
        ActiveSupport::Notifications.instrument(prefixed_key, metadata) do
          yield
        end
      end
    end
  end
end
