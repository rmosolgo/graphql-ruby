# frozen_string_literal: true

module Platform
  module Mutations
    IncrementThing = GraphQL::Relay::Mutation.define do
      name "IncrementThing"
      description "increments the thing by 1."
      visibility :internal
      minimum_accepted_scopes ["repo"]

      input_field(:thingId,
        !types.ID,
        "Thing ID to log.",
        option: :setting)

      return_field(
        :thingId,
        !types.ID,
        "Thing ID to log."
      )

      resolve -> (root_obj, inputs, context) do
        thing = Platform::Helpers::NodeIdentification.typed_object_from_id(Objects::Thing, inputs[:thingId], context)
        raise Errors::Validation.new("Thing not found.") unless thing

        ThingActivity.track(thing.id, Time.now.change(min: 0, sec: 0))

        { thingId: thing.global_relay_id }
      end
    end
  end
end
