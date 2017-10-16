# frozen_string_literal: true
require "graphql/object/build_type"
require "graphql/object/field"
require "graphql/object/resolvers"

module GraphQL
  class Object
    def initialize(object, context)
      @object = object
      @context = context
    end

    class << self
      # @return [String]
      def graphql_type_name(new_name = nil)
        if new_name
          @graphql_type_name = new_name
        else
          @graphql_type_name || self.name.split("::").last
        end
      end

      def description(new_description = nil)
        if new_description
          @description = new_description
        else
          @description
        end
      end

      def models(*model_classes)
        if model_classes.any?
          @models = model_classes
        else
          @models
        end
      end

      def implements(*new_interfaces)
        @own_interfaces = new_interfaces
      end

      def own_interfaces
        @own_interfaces = []
      end

      def interfaces
        if superclass.is_a?(GraphQL::Object)
          superclass.interfaces + own_interfaces
        else
          own_interfaces
        end
      end

      # Define a field on this object
      def field(*args, &block)
        fields << GraphQL::Object::Field.new(*args, &block)
      end

      # Fields defined on this class
      # TODO should this inherit?
      def fields
        @fields ||= []
      end

      # TODO this caching will not work with rebooting
      # @return [GraphQL::ObjectType]
      def to_graphql(schema:)
        @to_graphql ||= BuildType.build_object_type(schema, self)
      end
    end
  end
end
