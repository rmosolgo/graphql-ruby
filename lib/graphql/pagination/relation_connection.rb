# frozen_string_literal: true
require "graphql/pagination/connection"

module GraphQL
  module Pagination
    # A generic class for working with database query objects.
    class RelationConnection < Pagination::Connection
      def nodes
        load_nodes
        @nodes
      end

      def has_previous_page
        if @has_previous_page.nil?
          @has_previous_page = if @after_offset && @after_offset > 0
            true
          elsif last
            # See whether there are any nodes _before_ the current offset.
            # If there _is no_ current offset, then there can't be any nodes before it.
            # Assume that if the offset is positive, there are nodes before the offset.
            limited_nodes
            !(@paged_nodes_offset.nil? || @paged_nodes_offset == 0)
          else
            false
          end
        end
        @has_previous_page
      end

      def has_next_page
        if @has_next_page.nil?
          @has_next_page = if @before_offset && @before_offset > 0
            true
          elsif first
            relation_count(set_limit(sliced_nodes, first + 1)) == first + 1
          else
            false
          end
        end
        @has_next_page
      end

      def cursor_for(item)
        load_nodes
        # index in nodes + existing offset + 1 (because it's offset, not index)
        offset = nodes.index(item) + 1 + (@paged_nodes_offset || 0) + (relation_offset(items) || 0)
        context.schema.cursor_encoder.encode(offset.to_s)
      end

      private

      # @param relation [Object] A database query object
      # @return [Integer, nil] The offset value, or nil if there isn't one
      def relation_offset(relation)
        raise "#{self.class}#relation_offset(relation) must return the offset value for a #{relation.class} (#{relation.inspect})"
      end

      # @param relation [Object] A database query object
      # @return [Integer, nil] The limit value, or nil if there isn't one
      def relation_limit(relation)
        raise "#{self.class}#relation_limit(relation) must return the limit value for a #{relation.class} (#{relation.inspect})"
      end

      # @param relation [Object] A database query object
      # @return [Integer, nil] The number of items in this relation (hopefully determined without loading all records into memory!)
      def relation_count(relation)
        raise "#{self.class}#relation_count(relation) must return the count of records for a #{relation.class} (#{relation.inspect})"
      end

      # @param relation [Object] A database query object
      # @return [Object] A modified query object which will return no records
      def null_relation(relation)
        raise "#{self.class}#null_relation(relation) must return an empty relation for a #{relation.class} (#{relation.inspect})"
      end

      # @return [Integer]
      def offset_from_cursor(cursor)
        decode(cursor).to_i
      end

      # Abstract this operation so we can always ignore inputs less than zero.
      # (Sequel doesn't like it, understandably.)
      def set_offset(relation, offset_value)
        if offset_value >= 0
          relation.offset(offset_value)
        else
          relation.offset(0)
        end
      end

      # Abstract this operation so we can always ignore inputs less than zero.
      # (Sequel doesn't like it, understandably.)
      def set_limit(relation, limit_value)
        if limit_value > 0
          relation.limit(limit_value)
        elsif limit_value == 0
          null_relation(relation)
        else
          relation
        end
      end

      # Apply `before` and `after` to the underlying `items`,
      # returning a new relation.
      def sliced_nodes
        @sliced_nodes ||= begin
          paginated_nodes = items
          @after_offset = after && offset_from_cursor(after)
          @before_offset = before && offset_from_cursor(before)

          if @after_offset
            previous_offset = relation_offset(items) || 0
            paginated_nodes = set_offset(paginated_nodes, previous_offset + @after_offset)
          end

          if @before_offset && @after_offset
            if @after_offset < @before_offset
              # Get the number of items between the two cursors
              space_between = @before_offset - @after_offset - 1
              paginated_nodes = set_limit(paginated_nodes, space_between)
            else
              # TODO I think this is untested
              # The cursors overextend one another to an empty set
              paginated_nodes = null_relation(paginated_nodes)
            end
          elsif @before_offset
            # Use limit to cut off the tail of the relation
            paginated_nodes = set_limit(paginated_nodes, @before_offset - 1)
          end

          paginated_nodes
        end
      end

      # Apply `first` and `last` to `sliced_nodes`,
      # returning a new relation
      def limited_nodes
        @limited_nodes ||= begin
          paginated_nodes = sliced_nodes

          if first && (relation_limit(paginated_nodes).nil? || relation_limit(paginated_nodes) > first) && last.nil?
            # `first` would create a stricter limit that the one already applied, so add it
            paginated_nodes = set_limit(paginated_nodes, first)
          end

          if last
            if (lv = relation_limit(paginated_nodes))
              if last <= lv
                # `last` is a smaller slice than the current limit, so apply it
                offset = (relation_offset(paginated_nodes) || 0) + (lv - last)
                paginated_nodes = set_offset(paginated_nodes, offset)
                paginated_nodes = set_limit(paginated_nodes, last)
              end
            else
              # No limit, so get the last items
              sliced_nodes_count = relation_count(@sliced_nodes)
              offset = (relation_offset(paginated_nodes) || 0) + sliced_nodes_count - [last, sliced_nodes_count].min
              paginated_nodes = set_offset(paginated_nodes, offset)
              paginated_nodes = set_limit(paginated_nodes, last)
            end
          end

          @paged_nodes_offset = relation_offset(paginated_nodes)
          paginated_nodes
        end
      end

      # Load nodes after applying first/last/before/after,
      # returns an array of nodes
      def load_nodes
        # Return an array so we can consistently use `.index(node)` on it
        @nodes ||= limited_nodes.to_a
      end
    end
  end
end
