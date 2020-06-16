# frozen_string_literal: true

module GraphQL
  class Schema
    class Member
      module HasInvalidNullError
        # Set up a member-specific invalid null error
        # to use when this member's non-null fields wrongly return `nil`.
        # It should help with debugging and bug tracker integrations.
        def inherited(child_class)
          child_class.const_set(:InvalidNullError, Class.new(GraphQL::InvalidNullError))
          super
        end
      end
    end
  end
end
