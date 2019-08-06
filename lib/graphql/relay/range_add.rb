# frozen_string_literal: true
module GraphQL
  module Relay
    # This provides some isolation from `GraphQL::Relay` internals.
    #
    # Given a list of items and a new item, it will provide a connection and an edge.
    #
    # The connection doesn't receive outside arguments, so the list of items
    # should be ordered and paginated before providing it here.
    #
    # @example Adding a comment to list of comments
    #   post = Post.find(args[:postId])
    #   comments = post.comments
    #   new_comment = comments.build(body: args[:body])
    #   new_comment.save!
    #
    #   range_add = GraphQL::Relay::RangeAdd.new(
    #     parent: post,
    #     collection: comments,
    #     item: new_comment,
    #     context: ctx,
    #   )
    #
    #   response = {
    #     post: post,
    #     commentsConnection: range_add.connection,
    #     newCommentEdge: range_add.edge,
    #   }
    class RangeAdd
      attr_reader :edge, :connection, :parent

      # @param collection [Object] The list of items to wrap in a connection
      # @param item [Object] The newly-added item (will be wrapped in `edge_class`)
      # @param parent [Object] The owner of `collection`, will be passed to the connection if provided
      # @param context [GraphQL::Query::Context] The surrounding `ctx`, will be passed to the connection if provided (this is required for cursor encoders)
      # @param edge_class [Class] The class to wrap `item` with
      def initialize(collection:, item:, parent: nil, context: nil, edge_class: Relay::Edge)
        connection_class = BaseConnection.connection_for_nodes(collection)
        @parent = parent
        @connection = connection_class.new(collection, {}, parent: parent, context: context)
        @edge = edge_class.new(item, @connection)
      end
    end
  end
end
