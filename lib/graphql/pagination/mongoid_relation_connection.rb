# frozen_string_literal: true
#--
# typed: strict
require "graphql/pagination/relation_connection"

module GraphQL
  module Pagination
    class MongoidRelationConnection < Pagination::RelationConnection
      #: (untyped relation) -> Integer?
      def relation_offset(relation)
        relation.options.skip
      end

      #: (untyped relation) -> Integer?
      def relation_limit(relation)
        relation.options.limit
      end

      #: (untyped relation) -> Integer
      def relation_count(relation)
        relation.all.count(relation.options.slice(:limit, :skip))
      end

      #: (untyped relation) -> untyped
      def null_relation(relation)
        relation.without_options.none
      end
    end
  end
end
