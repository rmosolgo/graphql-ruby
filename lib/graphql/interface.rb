# frozen_string_literal: true
module GraphQL
  class Interface < GraphQL::SchemaMember
    class << self
      # Define a field on this object
      def field(*args, &block)
        fields << GraphQL::Object::Field.new(*args, &block)
      end

      # Fields defined on this class
      # TODO should this inherit?
      def fields
        @fields ||= []
      end

      def to_graphql
        @to_graphql ||= begin
          interface_class = self
          GraphQL::InterfaceType.define do
            name(interface_class.graphql_name)
            description(interface_class.description)
            # TODO dedup with object
            interface_class.fields.each do |field_inst|
              field_defn = field_inst.to_graphql
              # Based on the return type of the field, determine whether
              # we should wrap it with connection helpers or not.
              field_defn_method = if field_defn.type.unwrap.name =~ /Connection\Z/
                :connection
              else
                :field
              end
              field_name = field_defn.name
              public_send(field_defn_method, field_name, field: field_defn)
            end
          end
        end
      end
    end
  end
end
