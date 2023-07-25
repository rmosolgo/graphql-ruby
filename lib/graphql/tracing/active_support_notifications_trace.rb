# frozen_string_literal: true

require 'graphql/tracing/notifications_trace'

module GraphQL
  module Tracing
    # This implementation forwards events to ActiveSupport::Notifications
    # with a `graphql` suffix.
    module ActiveSupportNotificationsTrace
      include NotificationsTrace
      def initialize(engine: ActiveSupport::Notifications, **rest)
        super
      end
    end
  end
end
