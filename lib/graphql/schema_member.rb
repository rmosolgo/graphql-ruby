# frozen_string_literal: true
module GraphQL
  class SchemaMember
    module CachedGraphQLDefinition
      # A cached result of {.to_graphql}.
      # It's cached here so that user-overridden {.to_graphql} implementations
      # are also cached
      def graphql_definition
        @graphql_definition ||= to_graphql
      end
    end

    # Shared code for Object and Interface
    module HasFields
      # Define a field on this object
      def field(*args, &block)
        field_defn = field_class.new(*args, &block)
        fields.reject! { |f| f.name == field_defn.name }
        fields << field_defn
        nil
      end

      # Fields defined on this class
      # TODO should this inherit?
      def fields
        @fields ||= []
      end

      def field_class
        self::Field
      end
    end

    class << self
      include CachedGraphQLDefinition

      # Make the class act like its corresponding type (eg `connection_type`)
      def method_missing(method_name, *args, &block)
        if graphql_definition.respond_to?(method_name)
          graphql_definition.public_send(method_name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(method_name, incl_private = false)
        graphql_definition.respond_to?(method_name, incl_private) || super
      end

      # @return [String]
      def graphql_name(new_name = nil)
        if new_name
          @graphql_name = new_name
        else
          @graphql_name || self.name.split("::").last
        end
      end

      # @return [String]
      def description(new_description = nil)
        if new_description
          @description = new_description
        else
          @description
        end
      end

      def to_graphql
        raise NotImplementedError
      end
    end
  end
end
