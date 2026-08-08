# frozen_string_literal: true

module GraphQL
  class Schema
    class Member
      # These constants are interpreted as GraphQL types when defining fields or arguments
      #
      # **API:** private
      #
      # **Examples**
      #
      # **Example: field :is_draft, Boolean, null: false**
      #
      # ```ruby
      # field :id, ID, null: false
      # field :score, Int, null: false
      # ```
      module GraphQLTypeNames
        Boolean = "Boolean"
        ID = "ID"
        Int = "Int"
      end
    end
  end
end
