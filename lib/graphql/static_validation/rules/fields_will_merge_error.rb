# frozen_string_literal: true
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
        # Can't use `.include?` here because AST nodes implement `#==`
        # based on string value, not including location. But sometimes,
        # identical nodes conflict because of their differing return types.
        if nodes.any? { |n| n == node && n.line == node.line && n.col == node.col }
          # already have an error for this node
          return
        end

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
