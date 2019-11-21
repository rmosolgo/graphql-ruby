# frozen_string_literal: true

module GraphQL 
  class Schema
    class TypeMembership
      attr_reader :types, :visibility

      def initialize(types, visibility)
        @types = Array(types)
        @visibility = visibility
      end

      def visible?(_ctx)
        true
      end
    end
  end
end
