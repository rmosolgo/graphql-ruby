# frozen_string_literal: true
require "graphql/pagination/relation_connection"

module GraphQL
  module Pagination
    # Customizes `RelationConnection` to work with `ActiveRecord::Relation`s.
    class ActiveRecordRelationConnection < Pagination::RelationConnection
      private

      def relation_larger_than(relation, size)
        initial_offset = relation.offset_value || 0
        relation.offset(initial_offset + size).exists?
      end

      def relation_count(relation)
        int_or_hash = if relation.respond_to?(:unscope)
          relation.unscope(:order).count(:all)
        else
          # Rails 3
          relation.count
        end
        if int_or_hash.is_a?(Integer)
          int_or_hash
        else
          # Grouped relations return count-by-group hashes
          int_or_hash.length
        end
      end

      def relation_limit(relation)
        relation.limit_value
      end

      def relation_offset(relation)
        relation.offset_value
      end

      def null_relation(relation)
        if relation.respond_to?(:none)
          relation.none
        else
          # Rails 3
          relation.where("1=2")
        end
      end
    end
  end
end
