# frozen_string_literal: true

module GraphQL
  module Tracing
    # This implementation forwards events to ActiveSupport::Notifications
    # with a `graphql.` prefix.
    #
    # Installed automatically when `ActiveSupport::Notifications` is discovered.
    module ActiveSupportNotificationsTracing
      # A cache of frequently-used keys to avoid needless string allocations
      KEYS = {
        "lex" => "graphql.lex",
        "parse" => "graphql.parse",
        "validate" => "graphql.validate",
        "analyze.multiplex" => "graphql.analyze.multiplex",
        "analyze.query" => "graphql.analyze.query",
        "execute.eager" => "graphql.execute.eager",
        "execute.lazy" => "graphql.execute.lazy",
        "execute.field" => "graphql.execute.field",
        "execute.field.lazy" => "graphql.execute.field.lazy",
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
