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
        if some_early_check
          return { thing_id: "000" }
        end

        # These shouldn't be modified:
        { abcDef: 1 }
        some_method do { xyzAbc: 1 } end

        thing = Platform::Helpers::NodeIdentification.typed_object_from_id(Objects::Thing, inputs[:thing_id], context)
        raise Errors::Validation.new("Thing not found.") unless thing

        ThingActivity.track(thing.id, Time.now.change(min: 0, sec: 0))

        if random_condition
          { thing_id: thing.global_relay_id }
        elsif other_random_thing
          { :thing_id => "abc" }
        elsif something_else
          method_with_block {
            { thing_id: "pqr" }
          }
        elsif yet_another_thing
          begin
            { thing_id: "987" }
          rescue
            { thing_id: "789" }
          end
        else
          return {
            thing_id: "xyz"
          }
        end
      end
    end
  end
end
