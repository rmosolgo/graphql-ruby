require 'active_support/concern'
module GraphQL::Fieldable
  extend ActiveSupport::Concern

  included do
    def get_field(syntax_field)
      field_class = self.class.find_field(syntax_field.identifier)
      if syntax_field.identifier == "cursor"
        cursor
      elsif field_class.nil?
        raise GraphQL::FieldNotDefinedError.new(self.class.name, syntax_field.identifier)
      else
        field_class.new(query: query, owner: self, calls: syntax_field.calls)
      end
    end

    def get_edge(syntax_field)
      field_class = self.class.find_field(syntax_field.identifier)
      if field_class.nil?
        raise GraphQL::FieldNotDefinedError.new(self.class.name, syntax_field.identifier)
      else
        edge = field_class.new(query: query)
        collection_items = send(edge.method)
        edge_class = edge.edge_class
        node_class = edge.node_class
        edge_class.new(items: collection_items, node_class: node_class)
      end
    end

    class << self
      def fields
        @fields ||= []
      end

      def parent_fields
        superclass == Object ? [] : (superclass.fields + superclass.parent_fields)
      end

      def all_fields
        fields + parent_fields
      end

      def has_field?(identifier)
        !!find_field(identifier)
      end

      def find_field(identifier)
        all_fields.find { |f| f.const_get(:NAME) == identifier.to_s }
      end

      def field(field_name, extends: nil, method: nil, description: nil, type: nil)
        field_name = field_name.to_s
        raise "You already defined #{field_name}" if has_field?(field_name)
        field_class = GraphQL::Field.create_class({
          name: field_name,
          extends: extends,
          owner_class: self,
          method: method,
          description: description
        })
        fields << field_class
      end

      def edges(field_name, method: nil, description: nil, edge_class_name: nil, node_class_name: nil)
        field_name = field_name.to_s
        raise "You already defined #{field_name}" if has_field?(field_name)
        fields << GraphQL::Field.create_class({
          name: field_name,
          owner_class: self,
          method: method,
          description: description,
          edge_class_name: edge_class_name,
          node_class_name: node_class_name,
        })
      end
    end
  end
end