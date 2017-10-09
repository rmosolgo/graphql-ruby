# frozen_string_literal: true

module GraphQL
  module Relay
    # A connection implementation to expose SQL collection objects using stable
    # keyset pagination. All columns used in the sort order will have their
    # values saved in the resulting cursor. This should probably be paired with
    # an encrypted or at least signed/verified cursor encoder.
    #
    # It currently works only for Sequel::Dataset.
    class StableRelationConnection < GraphQL::Relay::BaseConnection
      def cursor_from_node(item)
        # TODO(bgentry): in the future this should use an encrypted cursor encoder,
        # possibly from GraphQL Pro.
        cursor_data = order_fields.map { |f, _result| item.public_send(f) }
        encode(cursor_data)
      end

      def has_next_page
        if first
          paged_nodes_length >= first && sliced_nodes_count > first
        elsif GraphQL::Relay::ConnectionType.bidirectional_pagination && before
          !nodes_with_pk.seek(value: cursor_selectors(before), include_exact_match: true).empty?
        else
          false
        end
      end

      def has_previous_page
        if last
          paged_nodes_length >= last && sliced_nodes_count > last
        elsif GraphQL::Relay::ConnectionType.bidirectional_pagination && after
          # Check if we've already paginated through the collection a bit and there
          # are nodes behind us.
          !nodes_with_pk.seek(value: cursor_selectors(after), include_exact_match: true).empty?
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
          if (relation_limit(items) && last <= relation_limit(items)) || !relation_limit(items)
            items = items.limit(last)
          end
          primary_key = items.model.primary_key
          # reverse the order again via a subselect *after* the limit is applied so that
          # we still get the last N nodes, but in their original order:
          items = items.unfiltered.unlimited.where(
            primary_key => items.select(primary_key)
          ).reverse
        end

        if max_page_size && !first && !last
          if relation_limit(items).nil? || relation_limit(items) > max_page_size
            items = items.limit(max_page_size)
          end
        end

        @paged_nodes = items
      end

      def relation_offset(relation)
        relation.opts[:offset]
      end

      def relation_limit(relation)
        relation.opts[:limit]
      end

      # If a relation contains a `.group` clause, a `.count` will return a Hash.
      def relation_count(relation)
        count_or_hash = relation.count
        count_or_hash.is_a?(Integer) ? count_or_hash : count_or_hash.length
      end

      # Apply cursors to edges
      def sliced_nodes
        return @sliced_nodes if defined? @sliced_nodes

        @sliced_nodes = nodes_with_pk
        @sliced_nodes = append_conditions(@sliced_nodes, cursor_selectors(after), false) if after
        @sliced_nodes = append_conditions(@sliced_nodes, cursor_selectors(before), true) if before
        @sliced_nodes
      end

      def nodes_with_pk
        return @nodes_with_pk if defined? @nodes_with_pk

        @nodes_with_pk = nodes
        primary_key = nodes.opts[:model].primary_key
        unless order_has_pk?(nodes, primary_key)
          @nodes_with_pk = nodes_with_pk.order_append(primary_key)
        end
        @nodes_with_pk
      end

      def order_has_pk?(sliced_nodes, pk)
        all_order_fields = sliced_nodes.opts[:order].map do |i|
          i.is_a?(Sequel::SQL::OrderedExpression) ? i.expression : i
        end
        all_order_fields.include?(pk)
      end

      def limit_nodes(sliced_nodes, limit)
        limit > 0 ? sliced_nodes.limit(limit) : sliced_nodes.where(false)
      end

      def sliced_nodes_count
        return @sliced_nodes_count if defined? @sliced_nodes_count

        # If a relation contains a `.group` clause, a `.count` will return a Hash.
        @sliced_nodes_count = relation_count(sliced_nodes)
      end

      def cursor_selectors(cursor)
        decode(cursor)
      end

      def paged_nodes_array
        return @paged_nodes_array if defined?(@paged_nodes_array)
        @paged_nodes_array = paged_nodes.to_a
      end

      def paged_nodes_length
        paged_nodes_array.length
      end

      def order_fields
        return @order_fields if defined? @order_fields

        sliced_nodes.opts[:order].map do |i|
          i.is_a?(Sequel::SQL::OrderedExpression) ? i.expression : i
        end
      end

      # add where conditions for each cursor selector in the appropriate direction
      def append_conditions(sliced_nodes, values, reversed)
        if reversed
          # reverse the order so we can select the last N nodes:
          sliced_nodes.reverse.seek(value: values)
        else
          sliced_nodes.seek(value: values)
        end
      end
    end
  end
end
