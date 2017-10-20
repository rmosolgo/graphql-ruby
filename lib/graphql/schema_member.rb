# frozen_string_literal: true
module GraphQL
  class SchemaMember
    class << self
      # @return [String]
      def graphql_name(new_name = nil)
        if new_name
          @graphql_name = new_name
        else
          @graphql_name || self.name.split("::").last
        end
      end

      def description(new_description = nil)
        if new_description
          @description = new_description
        else
          @description
        end
      end

      # TODO implement this here?
      def to_graphql
        raise NotImplementedError
      end
    end
  end
end
