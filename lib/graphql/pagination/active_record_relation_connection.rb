# frozen_string_literal: true
require "graphql/pagination/relation_connection"

module GraphQL
  module Pagination
    # Customizes `RelationConnection` to work with `ActiveRecord::Relation`s.
    class ActiveRecordRelationConnection < Pagination::RelationConnection
      def relation_count(relation)
        if relation.respond_to?(:unscope)
          relation.unscope(:order).count(:all)
        else
          # Rails 3
          relation.count
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
