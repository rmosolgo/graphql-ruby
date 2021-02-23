# frozen_string_literal: true

module GraphQL
  module Tracing
    # This implementation forwards events to ActiveSupport::Notifications
    # with a `graphql` suffix.
    #
    # @see KEYS for event names
    module ActiveSupportNotificationsTracing
      # A cache of frequently-used keys to avoid needless string allocations
      KEYS = {
        "lex" => "lex.graphql",
        "parse" => "parse.graphql",
        "validate" => "validate.graphql",
        "analyze_multiplex" => "analyze_multiplex.graphql",
        "analyze_query" => "analyze_query.graphql",
        "execute_query" => "execute_query.graphql",
        "execute_query_lazy" => "execute_query_lazy.graphql",
        "execute_field" => "execute_field.graphql",
        "execute_field_lazy" => "execute_field_lazy.graphql",
        "authorized" => "authorized.graphql",
        "authorized_lazy" => "authorized_lazy.graphql",
        "resolve_type" => "resolve_type.graphql",
        "resolve_type_lazy" => "resolve_type.graphql",
      }

      def self.trace(key, metadata)
        prefixed_key = KEYS[key] || "#{key}.graphql"
        ActiveSupport::Notifications.instrument(prefixed_key, metadata) do
          yield
        end
      end
    end
  end
end
