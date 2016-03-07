module GraphQL
  module DefinitionHelpers
    # Accepts a hash with symbol keys.
    # - convert keys to strings
    # - if the value responds to `name=`, then assign the hash key as `name`
    #
    # Used by {ObjectType#fields}, {Field#arguments} and others.
    class StringNamedHash
      # Normalized hash for the input
      # @return [Hash] Hash with string keys
      attr_reader :to_h

      # @param input_hash [Hash] Hash to be normalized
      def initialize(input_hash)
        @to_h = input_hash
                .reduce({}) { |memo, (key, value)| memo[key.to_s] = value; memo }
        # Set the name of the value based on its key
        @to_h.each {|k, v| v.respond_to?("name=") && v.name = k }
      end
    end
  end
end
