# frozen_string_literal: true
module GraphQL
  class Schema
    class Implementation
      # This is used when no user-provided type is found
      class TypeMissing < GraphQL::Object
      end
    end
  end
end
