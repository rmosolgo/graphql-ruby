# frozen_string_literal: true

module GraphQL
  class Schema
    class Member
      # Set up a type-specific error to make debugging & bug tracker integration better
      module HasUnresolvedTypeError
        private
        def add_unresolved_type_error(child_class)
          child_class.const_set(:UnresolvedTypeError, Class.new(GraphQL::UnresolvedTypeError))
        end
      end
    end
  end
end
