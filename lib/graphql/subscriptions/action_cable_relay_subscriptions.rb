# frozen_string_literal: true
class GraphQL::Subscriptions::ActionCableRelaySubscriptions < GraphQL::Subscriptions::ActionCableSubscriptions
  # Works exactly the same as ActionCableSubscriptions class except uses a stream format that Relay will understand.
  def execute_all(event, object)
    stream = [EVENT_PREFIX, ":", event.name, ":", event.arguments.to_a.join(":")].join
    ActionCable.server.broadcast(stream, object.id)
  end
end

