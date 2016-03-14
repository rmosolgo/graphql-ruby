module GraphQL
  module Define
    # Create a hash of definitions out of provided arguments.
    #
    # @example Create definitions (some default, some custom)
    #    hash = AssignmentDictionary.create(:name, :description, field: (value, field_name) -> { value.create_field(field) })
    #
    module AssignmentDictionary
      # Turn `keys` into a hash suitable for {GraphQL::Define::InstanceDefinable}
      # @param Any number of symbols for default assignment, followed by an (optional) hash of custom assignment procs.
      # @return [Hash] keys are attributes which may be defined. values are procs which assign values to the target object.
      def self.create(*keys)
        initial = if keys.last.is_a?(Hash)
          keys.pop
        else
          {}
        end
        keys.inject(initial) do |memo, key|
          assign_key = "#{key}="
          memo[key] = -> (target, value) { target.public_send(assign_key, value) }
          memo
        end
      end
    end
  end
end
