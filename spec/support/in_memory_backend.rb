# frozen_string_literal: true
class InMemoryBackend
  class Subscriptions < GraphQL::Subscriptions
    attr_reader :deliveries, :pushes, :extra, :queries, :events

    def initialize(schema:, extra:, **rest)
      super
      @extra = extra
      @queries = {}
      # { topic => { fingerprint => [sub_id, ... ] } }
      @events = Hash.new { |h,k| h[k] = Hash.new { |h2, k2| h2[k2] = [] } }
      @deliveries = Hash.new { |h, k| h[k] = [] }
      @pushes = []
    end

    def write_subscription(query, events)
      subscription_id = query.context[:subscription_id] = build_id
      @queries[subscription_id] = query
      events.each do |ev|
        @events[ev.topic][ev.fingerprint] << subscription_id
      end
    end

    def read_subscription(subscription_id)
      query = @queries[subscription_id]
      if query
        {
          query_string: query.query_string,
          operation_name: query.operation_name,
          variables: query.provided_variables,
          context: {
            me: query.context[:me],
            validate_update: query.context[:validate_update],
            other_int: query.context[:other_int],
            hidden_event: query.context[:hidden_event],
          },
          transport: :socket,
        }
      else
        nil
      end
    end

    def delete_subscription(subscription_id)
      @queries.delete(subscription_id)
      @events.each do |topic, sub_ids_by_fp|
        sub_ids_by_fp.each do |fp, sub_ids|
          sub_ids.delete(subscription_id)
          if sub_ids.empty?
            sub_ids_by_fp.delete(fp)
            if sub_ids_by_fp.empty?
              @events.delete(topic)
            end
          end
        end
      end
    end

    def execute_all(event, object)
      topic = event.topic
      sub_ids_by_fp = @events[topic]
      sub_ids_by_fp.each do |fingerprint, sub_ids|
        result = execute_update(sub_ids.first, event, object)
        if !result.nil?
          sub_ids.each do |sub_id|
            deliver(sub_id, result)
          end
        end
      end
    end

    def deliver(subscription_id, result)
      query = @queries[subscription_id]
      socket = query.context[:socket] || subscription_id
      @deliveries[socket] << result
    end

    def execute_update(subscription_id, event, object)
      query = @queries[subscription_id]
      if query
        @pushes << query.context[:socket]
      end
      super
    end

    # Just for testing:
    def reset
      @queries.clear
      @events.clear
      @deliveries.clear
      @pushes.clear
    end
  end

  # Just a random stateful object for tracking what happens:
  class SubscriptionPayload
    attr_reader :str

    def initialize
      @str = "Update"
      @counter = 0
    end

    def int
      @counter += 1
    end
  end
end
