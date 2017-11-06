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
        add_field(field_defn)
        nil
      end

      def fields
        all_fields = own_fields
        inherited_fields = (superclass.is_a?(HasFields) ? superclass.fields : [])
        # Remove any inherited fields which were overridden on this class:
        inherited_fields.each do |inherited_f|
          if all_fields.none? {|f| f.name == inherited_f.name }
            all_fields << inherited_f
          end
        end
        all_fields
      end

      # Register this field with the class, overriding a previous one if needed
      def add_field(field_defn)
        fields.reject! { |f| f.name == field_defn.name }
        own_fields << field_defn
      end

      def own_fields
        @own_fields ||= []
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
          @description || (superclass <= GraphQL::SchemaMember ? superclass.description : nil)
        end
      end

      def to_graphql
        raise NotImplementedError
      end

      def to_list_type
        ListTypeProxy.new(self)
      end

      def to_non_null_type
        NonNullTypeProxy.new(self)
      end
    end

    class ListTypeProxy
      include GraphQL::SchemaMember::CachedGraphQLDefinition

      def initialize(member)
        @member = member
      end

      def to_graphql
        @member.graphql_definition.to_list_type
      end
    end

    class NonNullTypeProxy
      include GraphQL::SchemaMember::CachedGraphQLDefinition

      def initialize(member)
        @member = member
      end

      def to_graphql
        @member.graphql_definition.to_non_null_type
      end
    end
  end
end
