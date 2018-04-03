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

      resolve ->(root_obj, inputs, context) do
        if some_early_check
          return { thingId: "000" }
        end

        # These shouldn't be modified:
        { abcDef: 1 }
        some_method do { xyzAbc: 1 } end

        thing = Platform::Helpers::NodeIdentification.typed_object_from_id(Objects::Thing, inputs[:thingId], context)
        raise Errors::Validation.new("Thing not found.") unless thing

        ThingActivity.track(thing.id, Time.now.change(min: 0, sec: 0))


        if random_condition
          { thingId: thing.global_relay_id }
        elsif other_random_thing
          { :thingId => "abc" }
        elsif something_else
          method_with_block {
            { thingId: "pqr" }
          }
        elsif yet_another_thing
          begin
            { thingId: "987" }
          rescue
            { thingId: "789" }
          end
        else
          return {
            thingId: "xyz"
          }
        end
      end
    end
  end
end
