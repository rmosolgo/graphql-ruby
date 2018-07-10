# frozen_string_literal: true

module Platform
  module Interfaces
    module Subscribable
      include Platform::Interfaces::Base
      description "Entities that can be subscribed to for web and email notifications."

      field :id, GraphQL::ID_TYPE, method: :global_relay_id, null: false

      field :viewer_subscription, Enums::SubscriptionState, description: "Identifies if the viewer is watching, not watching, or ignoring the subscribable entity.", null: false

      def viewer_subscription
        if context[:viewer].nil?
          return "unsubscribed"
        end

        subscription_status_response = object.async_subscription_status(context[:viewer]).sync

        if subscription_status_response.failed?
          error = Platform::Errors::ServiceUnavailable.new("Subscriptions are currently unavailable. Please try again later.")
          error.ast_node = context.irep_node.ast_node
          error.path = context.path
          context.errors << error
          return "unavailable"
        end

        subscription = subscription_status_response.value
        if subscription.included?
          "unsubscribed"
        elsif subscription.subscribed?
          "subscribed"
        elsif subscription.ignored?
          "ignored"
        end
      end

      field :viewer_can_subscribe, Boolean, description: "Check if the viewer is able to change their subscription status for the repository.", null: false

      def viewer_can_subscribe
        return false if context[:viewer].nil?

        object.async_subscription_status(context[:viewer]).then(&:success?)
      end

      field :issues, function: Platform::Functions::Issues.new, description: "A list of issues associated with the milestone.", connection: true
      field :files, Connections.define(PackageFile), description: "List of files associated with this registry package version", null: false, connection: true
      field :enabled, Boolean, "Whether enabled for this project", method: :enabled?, null: false
    end
  end
end
