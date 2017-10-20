# frozen_string_literal: true
module GraphQL
  class SchemaMember
    class << self
      # Make the class act like its corresponding type (eg `connection_type`)
      def method_missing(method_name, *args, &block)
        if to_graphql.respond_to?(method_name)
          to_graphql.public_send(method_name, *args, &block)
        else
          super
        end
      end

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
