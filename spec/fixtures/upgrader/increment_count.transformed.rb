# frozen_string_literal: true

module Platform
  module Mutations
    class IncrementThing < Mutations::BaseMutation
      description "increments the thing by 1."
      visibility :internal
      minimum_accepted_scopes ["repo"]

      argument :thing_id, ID, "Thing ID to log.", option: :setting, required: true

      field :thing_id, ID, "Thing ID to log.", null: false

      def resolve(**inputs)
        thing = Platform::Helpers::NodeIdentification.typed_object_from_id(Objects::Thing, inputs[:thing_id], @context)
        raise Errors::Validation.new("Thing not found.") unless thing

        ThingActivity.track(thing.id, Time.now.change(min: 0, sec: 0))

        { thingId: thing.global_relay_id }
      end
    end
  end
end
