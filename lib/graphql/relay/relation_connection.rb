# frozen_string_literal: true
module GraphQL
  module Relay
    # A connection implementation to expose SQL collection objects.
    # It works for:
    # - `ActiveRecord::Relation`
    # - `Sequel::Dataset`
    class RelationConnection < BaseConnection
      def cursor_from_node(item)
        item_index = paged_nodes_array.index(item)
        if item_index.nil?
          raise("Can't generate cursor, item not found in connection: #{item}")
        else
          offset = item_index + 1 + ((relation_offset(paged_nodes) || 0) - (relation_offset(sliced_nodes) || 0))

          if after
            offset += offset_from_cursor(after)
          elsif before
            offset += offset_from_cursor(before) - 1 - sliced_nodes_count
          end

          encode(offset.to_s)
        end
      end

      def has_next_page
        if first
          paged_nodes_length >= first && sliced_nodes_count > first
        elsif GraphQL::Relay::ConnectionType.bidirectional_pagination && last
          sliced_nodes_count > last
        else
          false
        end
      end

      def has_previous_page
        if last
          paged_nodes_length >= last && sliced_nodes_count > last
        elsif GraphQL::Relay::ConnectionType.bidirectional_pagination && after
          # We've already paginated through the collection a bit,
          # there are nodes behind us
          offset_from_cursor(after) > 0
        else
          false
        end
      end

      def first
        return @first if defined? @first

        @first = get_limited_arg(:first)
        @first = max_page_size if @first && max_page_size && @first > max_page_size
        @first
      end

      def last
        return @last if defined? @last

        @last = get_limited_arg(:last)
        @last = max_page_size if @last && max_page_size && @last > max_page_size
        @last
      end

      private

      # apply first / last limit results
      def paged_nodes
        return @paged_nodes if defined? @paged_nodes

        items = sliced_nodes

        if first
          if relation_limit(items).nil? || relation_limit(items) > first
            items = items.limit(first)
          end
        end

        if last
          if relation_limit(items)
            if last <= relation_limit(items)
              offset = (relation_offset(items) || 0) + (relation_limit(items) - last)
              items = items.offset(offset).limit(last)
            end
          else
            slice_count = relation_count(items)
            offset = (relation_offset(items) || 0) + slice_count - [last, slice_count].min
            items = items.offset(offset).limit(last)
          end
        end

        if max_page_size && !first && !last
          if relation_limit(items).nil? || relation_limit(items) > max_page_size
            items = items.limit(max_page_size)
          end
        end

        @paged_nodes = items
      end

      def relation_offset(relation)
        if relation.respond_to?(:offset_value)
          relation.offset_value
        else
          relation.opts[:offset]
        end
      end

      def relation_limit(relation)
        if relation.respond_to?(:limit_value)
          relation.limit_value
        else
          relation.opts[:limit]
        end
      end

      # If a relation contains a `.group` clause, a `.count` will return a Hash.
      def relation_count(relation)
        count_or_hash = if(defined?(ActiveRecord::Relation) && relation.is_a?(ActiveRecord::Relation))
          relation.count(:all)
        else # eg, Sequel::Dataset, don't mess up others
          relation.count
        end
        count_or_hash.is_a?(Integer) ? count_or_hash : count_or_hash.length
      end

      # Apply cursors to edges
      def sliced_nodes
        return @sliced_nodes if defined? @sliced_nodes

        @sliced_nodes = nodes

        if after
          offset = (relation_offset(@sliced_nodes) || 0) + offset_from_cursor(after)
          @sliced_nodes = @sliced_nodes.offset(offset)
        end

        if before && after
          if offset_from_cursor(after) < offset_from_cursor(before)
            @sliced_nodes = limit_nodes(@sliced_nodes,  offset_from_cursor(before) - offset_from_cursor(after) - 1)
          else
            @sliced_nodes = limit_nodes(@sliced_nodes, 0)
          end

        elsif before
          @sliced_nodes = limit_nodes(@sliced_nodes, offset_from_cursor(before) - 1)
        end

        @sliced_nodes
      end

      def limit_nodes(sliced_nodes, limit)
        if limit > 0 || defined?(ActiveRecord::Relation) && sliced_nodes.is_a?(ActiveRecord::Relation)
          sliced_nodes.limit(limit)
        else
          sliced_nodes.where(false)
        end
      end

      def sliced_nodes_count
        return @sliced_nodes_count if defined? @sliced_nodes_count

        # If a relation contains a `.group` clause, a `.count` will return a Hash.
        @sliced_nodes_count = relation_count(sliced_nodes)
      end

      def offset_from_cursor(cursor)
        decode(cursor).to_i
      end

      def paged_nodes_array
        return @paged_nodes_array if defined?(@paged_nodes_array)
        @paged_nodes_array = paged_nodes.to_a
      end

      def paged_nodes_length
        if paged_nodes.respond_to?(:length)
          paged_nodes.length
        else
          paged_nodes_array.length
        end
      end
    end

    if defined?(ActiveRecord::Relation)
      BaseConnection.register_connection_implementation(ActiveRecord::Relation, RelationConnection)
    end
    if defined?(Sequel::Dataset)
      BaseConnection.register_connection_implementation(Sequel::Dataset, RelationConnection)
    end
  end
end
