# frozen_string_literal: true
# typed: true
module GraphQL
  module StaticValidation
    class FieldsWillMergeError < StaticValidation::Error
      attr_reader :field_name
      attr_reader :kind

      def initialize(kind:, field_name:)
        super(nil)

        @field_name = field_name
        @kind = kind
        @conflicts = []
        # Indexes of `@nodes`, so that `add_conflict` doesn't compare `node` with each one
        @node_ids = {}.compare_by_identity #: Hash[GraphQL::Language::Nodes::AbstractNode, bool]
        @nodes_by_location = nil #: Hash[Integer?, Hash[Integer?, Array[GraphQL::Language::Nodes::AbstractNode]]]?
      end

      def message
        @message || "Field '#{field_name}' has #{kind == :argument ? 'an' : 'a'} #{kind} conflict: #{conflicts}?"
      end

      attr_writer :message

      def path
        []
      end

      def conflicts
        @conflicts.join(' or ')
      end

      def add_conflict(node, conflict_str)
        # Check if we already have an error for this exact node.
        # Use object identity first (fast path), then fall back to
        # value + location comparison for duplicate AST nodes.
        return if @node_ids.key?(node)

        nodes_at_line = (@nodes_by_location ||= {})[node.line] ||= {}
        nodes_at_location = nodes_at_line[node.col]
        if nodes_at_location
          # already have an error for this node
          return if nodes_at_location.any? { |n| n == node }
          nodes_at_location << node
        else
          nodes_at_line[node.col] = [node]
        end

        @node_ids[node] = true
        @nodes << node
        @conflicts << conflict_str
      end

      # A hash representation of this Message
      def to_h
        extensions = {
          "code" => code,
          "fieldName" => field_name,
          "conflicts" => conflicts
        }

        super.merge({
          "extensions" => extensions
        })
      end

      def code
        "fieldConflict"
      end
    end
  end
end
