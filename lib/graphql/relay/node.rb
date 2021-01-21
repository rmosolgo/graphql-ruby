# frozen_string_literal: true
module GraphQL
  module Relay
    # Helpers for working with Relay-specific Node objects.
    module Node
      # @return [GraphQL::Field] a field for finding objects by their global ID.
      def self.field(**kwargs, &block)
        GraphQL::Deprecation.warn "GraphQL::Relay::Node.field will be removed from GraphQL-Ruby 2.0, use GraphQL::Types::Relay::NodeField instead"
        # We have to define it fresh each time because
        # its name will be modified and its description
        # _may_ be modified.
        field = GraphQL::Types::Relay::NodeField.graphql_definition

        if kwargs.any? || block
          field = field.redefine(**kwargs, &block)
        end

        field
      end

      def self.plural_field(**kwargs, &block)
        GraphQL::Deprecation.warn "GraphQL::Relay::Nodes.field will be removed from GraphQL-Ruby 2.0, use GraphQL::Types::Relay::NodesField instead"
        field = GraphQL::Types::Relay::NodesField.graphql_definition

        if kwargs.any? || block
          field = field.redefine(**kwargs, &block)
        end

        field
      end

      # @return [GraphQL::InterfaceType] The interface which all Relay types must implement
      def self.interface
        GraphQL::Deprecation.warn "GraphQL::Relay::Node.interface will be removed from GraphQL-Ruby 2.0, use GraphQL::Types::Relay::Node instead"
        @interface ||= GraphQL::Types::Relay::Node.graphql_definition
      end
    end
  end
end
