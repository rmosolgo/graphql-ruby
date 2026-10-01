# frozen_string_literal: true

require "graphql/tracing/notifications_trace"

module GraphQL
  module Tracing
    # This implementation forwards events to ActiveSupport::Notifications with a `graphql` suffix.
    #
    # **Examples**
    #
    # **Example: Sending execution events to ActiveSupport::Notifications**
    #
    # ```ruby
    # class MySchema < GraphQL::Schema
    #   trace_with(GraphQL::Tracing::ActiveSupportNotificationsTrace)
    # end
    # ```
    #
    # **Example: Subscribing to GraphQL events with ActiveSupport::Notifications**
    #
    # ```ruby
    # ActiveSupport::Notifications.subscribe(/graphql/) do |event|
    #   pp event.name
    #   pp event.payload
    # end
    # ```
    module ActiveSupportNotificationsTrace
      include NotificationsTrace
      def initialize(engine: ActiveSupport::Notifications, **rest)
        super
      end
    end
  end
end
