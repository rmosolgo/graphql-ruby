# frozen_string_literal: true

module GraphQL
  class Schema
    class Member
      # A class which generates fields based on some configuration
      # may extend this module and extend the {#field_signature} method
      # to add options to the generated field.
      module GeneratesField
        # @return [Hash] Keywords for the `field(...)` method
        def field_signature
          {
            arguments: {},
          }
        end
      end
    end
  end
end
