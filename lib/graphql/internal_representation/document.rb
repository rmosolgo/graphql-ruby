# frozen_string_literal: true
module GraphQL
  module InternalRepresentation
    class Document
      # @return [Hash<String, Node>] Operation Nodes of this query
      attr_reader :operation_definitions

      # @return [Hash<String, Node>] Fragment definition Nodes of this query
      attr_reader :fragment_definitions

      def initialize
        @operation_definitions = {}
        @fragment_definitions = {}
      end

      def [](key)
        GraphQL::Deprecation.warn "#{self.class}#[] is deprecated; use `operation_definitions[]` instead"
        operation_definitions[key]
      end

      def each(&block)
        GraphQL::Deprecation.warn "#{self.class}#each is deprecated; use `operation_definitions.each` instead"
        operation_definitions.each(&block)
      end
    end
  end
end
