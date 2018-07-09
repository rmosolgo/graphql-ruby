# frozen_string_literal: true

module Platform
  module Interfaces
    Subscribable = GraphQL::InterfaceType.define do
      name "Subscribable"
      description "Entities that can be subscribed to for web and email notifications."

      field :id, !GraphQL::ID_TYPE, property: :global_relay_id

      field :viewerSubscription, -> { !Enums::SubscriptionState } do
        description "Identifies if the viewer is watching, not watching, or ignoring the subscribable entity."

        resolve ->(subscribable, arguments, context) do
          if context[:viewer].nil?
            return "unsubscribed"
          end

          subscription_status_response = subscribable.async_subscription_status(context[:viewer]).sync

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
      end

      field :viewerCanSubscribe, !types.Boolean do
        description "Check if the viewer is able to change their subscription status for the repository."

        resolve ->(subscribable, arguments, context) do
          return false if context[:viewer].nil?

          subscribable.async_subscription_status(context[:viewer]).then(&:success?)
        end
      end

      connection :issues, function: Platform::Functions::Issues.new, description: "A list of issues associated with the milestone."
      connection :files, -> { !Connections.define(PackageFile) }, description: "List of files associated with this registry package version"
      field :enabled, !types.Boolean, "Whether enabled for this project", property: :enabled?
    end
  end
end
