# frozen_string_literal: true
#--
# typed: strict

module GraphQL
  class Schema
    class Member
      # Set up a type-specific error to make debugging & bug tracker integration better
      module HasUnresolvedTypeError
        private
        #: (Module[untyped] child_class) -> void
        def add_unresolved_type_error(child_class)
          if child_class.name # Don't set this for anonymous classes
            child_class.const_set(:UnresolvedTypeError, Class.new(GraphQL::UnresolvedTypeError))
          else
            child_class.const_set(:UnresolvedTypeError, UnresolvedTypeError)
          end
        end
      end
    end
  end
end
