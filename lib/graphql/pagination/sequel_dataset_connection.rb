# frozen_string_literal: true
#--
# typed: strict
require "graphql/pagination/relation_connection"

module GraphQL
  module Pagination
    # Customizes `RelationConnection` to work with `Sequel::Dataset`s.
    class SequelDatasetConnection < Pagination::RelationConnection
      private

      #: (untyped relation) -> Integer?
      def relation_offset(relation)
        relation.opts[:offset]
      end

      #: (untyped relation) -> Integer?
      def relation_limit(relation)
        relation.opts[:limit]
      end

      #: (untyped relation) -> Integer
      def relation_count(relation)
        # Remove order to make it faster
        relation.order(nil).count
      end

      #: (untyped relation) -> untyped
      def null_relation(relation)
        relation.where(false)
      end
    end
  end
end
