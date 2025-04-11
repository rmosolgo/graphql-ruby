# frozen_string_literal: true
module Graphql
  class Dashboard < Rails::Engine
    module Subscriptions
      class BaseController < Graphql::Dashboard::ApplicationController
        include Installable

        def feature_installed?
          schema_class.subscriptions.is_a?(GraphQL::Pro::Subscriptions)
        end

        INSTALLABLE_COMPONENT_HEADER_HTML = "GraphQL-Pro Subscriptions aren't installed on this schema yet.".html_safe
        INSTALLABLE_COMPONENT_MESSAGE_HTML = <<-HTML.html_safe
          Deliver live updates over
          <a href="https://graphql-ruby.org/subscriptions/pusher_implementation.html">Pusher</a> or
          <a href="https://graphql-ruby.org/subscriptions/ably_implementation.html"> Ably</a>
          with GraphQL-Pro's subscription integrations.
        HTML
      end

      class TopicsController < BaseController
        def show
          topic_name = params[:name]
          all_subscription_ids = []
          schema_class.subscriptions.each_subscription_id(topic_name) do |sid|
            all_subscription_ids << sid
          end

          page = params[:page]&.to_i || 1
          limit = params[:per_page]&.to_i || 20
          offset = limit * (page - 1)
          subscription_ids = all_subscription_ids[offset, limit]
          subs = schema_class.subscriptions.read_subscriptions(subscription_ids)
          show_broadcast_subscribers_count = schema_class.subscriptions.show_broadcast_subscribers_count?
          subs.each do |sub|
            sub[:is_broadcast] = is_broadcast = schema_class.subscriptions.broadcast_subscription_id?(sub[:id])
            if is_broadcast && show_broadcast_subscribers_count
              sub[:subscribers_count] = sub_count =schema_class.subscriptions.count_broadcast_subscribed(sub[:id])
              sub[:still_subscribed] = sub_count > 0
            else
              sub[:still_subscribed] = schema_class.subscriptions.still_subscribed?(sub[:id])
              sub[:subscribers_count] = nil
            end
          end

          @topic_last_triggered_at = schema_class.subscriptions.topic_last_triggered_at(topic_name)
          @subscriptions = subs
          @subscriptions_count = all_subscription_ids.size
          @show_broadcast_subscribers_count = show_broadcast_subscribers_count
          @has_next_page = all_subscription_ids.size > offset + limit ? page + 1 : false
        end

        def index
          page = params[:page]&.to_i || 1
          per_page = params[:per_page]&.to_i || 20
          offset = per_page * (page - 1)
          limit = per_page
          topics, all_topics_count, has_next_page = schema_class.subscriptions.topics(offset: offset, limit: limit)

          @topics = topics
          @all_topics_count = all_topics_count
          @has_next_page = has_next_page
          @page = page
        end
      end

      class SubscriptionsController < BaseController
        def show
          subscription_id = params[:id]
          subscriptions = schema_class.subscriptions
          query_data = subscriptions.read_subscription(subscription_id)
          is_broadcast = subscriptions.broadcast_subscription_id?(subscription_id)

          if is_broadcast && subscriptions.show_broadcast_subscribers_count?
            subscribers_count = subscriptions.count_broadcast_subscribed(subscription_id)
            is_still_subscribed = subscribers_count > 0
          else
            subscribers_count = nil
            is_still_subscribed = subscriptions.still_subscribed?(subscription_id)
          end

          @query_data = query_data
          @still_subscribed = is_still_subscribed
          @is_broadcast = is_broadcast
          @subscribers_count = subscribers_count
        end

        def clear_all
          schema_class.subscriptions.clear
          flash[:success] = "All subscription data cleared."
          head :no_content
        end
      end
    end
  end
end
