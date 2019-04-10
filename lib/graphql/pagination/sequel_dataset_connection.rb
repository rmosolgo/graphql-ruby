# frozen_string_literal: true
require "graphql/pagination/connection"

module GraphQL
  module Pagination
    class SequelDatasetConnection < Pagination::Connection
      def nodes
        load_nodes
        @nodes
      end

      def has_previous_page
        load_nodes
        @has_previous_page
      end

      def has_next_page
        load_nodes
        @has_next_page
      end

      def cursor_for(item)
        load_nodes
        # index in nodes + existing offset + 1 (because it's offset, not index)
        offset = nodes.index(item) + 1 + (@paged_nodes_offset || 0) + (items.opts[:offset] || 0)
        context.schema.cursor_encoder.encode(offset.to_s)
      end

      private

      def offset_from_cursor(cursor)
        decode(cursor).to_i
      end

      # Populate all the pagination info _once_,
      # It doesn't do anything on subsequent calls.
      def load_nodes
        @nodes ||= begin
          sliced_nodes = items
          # Sequel doesn't handle offsets less than zero, so sanitize here.
          after_offset = after && offset_from_cursor(after)
          if after_offset && after_offset < 0
            after_offset = nil
          end

          before_offset = before && offset_from_cursor(before)
          if before_offset && before_offset < 0
            before_offset = nil
          end

          if after_offset
            previous_offset = items.opts[:offset] || 0
            sliced_nodes = sliced_nodes.offset(previous_offset + after_offset)
          end

          if before_offset && after_offset
            if after_offset < before_offset
              # Get the number of items between the two cursors
              space_between = before_offset - after_offset - 1
              sliced_nodes = sliced_nodes.limit(space_between)
            else
              # The cursors overextend one another to an empty set
              sliced_nodes = sliced_nodes.none
            end
          elsif before_offset
            # Use limit to cut off the tail of the relation
            sliced_nodes = sliced_nodes.limit(before_offset - 1)
          end


          sliced_nodes_count = if sliced_nodes.respond_to?(:unscope)
            sliced_nodes.unscope(:order).count(:all)
          else
            # Rails 3
            sliced_nodes.count
          end
          paged_nodes = sliced_nodes

          if first && (paged_nodes.opts[:limit].nil? || paged_nodes.opts[:limit] > first)
            # `first` would create a stricter limit that the one already applied, so add it
            paged_nodes = paged_nodes.limit(first)
          end

          if last
            if (lv = paged_nodes.opts[:limit])
              if last <= lv
                # `last` is a smaller slice than the current limit, so apply it
                offset = (paged_nodes.opts[:offset] || 0) + (lv - last)
                paged_nodes = paged_nodes.offset(offset).limit(last)
              end
            else
              # No limit, so get the last items
              offset = (paged_nodes.opts[:offset] || 0) + sliced_nodes_count - [last, sliced_nodes_count].min
              paged_nodes = paged_nodes.offset(offset).limit(last)
            end
          end

          # Apply max page size if nothing else was applied
          if max_page_size && !first && !last
            existing_limit = paged_nodes.opts[:limit]
            if existing_limit.nil? || existing_limit > max_page_size
              paged_nodes = paged_nodes.limit(max_page_size)
            end
          end

          @has_next_page = !!(
            (before_offset && before_offset > 0) ||
            (first && sliced_nodes_count > first)
          )

          @has_previous_page = !!(
            (after_offset && after_offset > 0) ||
            (last && sliced_nodes_count > last)
          )

          @paged_nodes_offset = paged_nodes.opts[:offset]
          # Make an array so that `.cursor_for` can call `.index` on it.
          paged_nodes.to_a
        end
      end
    end
  end
end
