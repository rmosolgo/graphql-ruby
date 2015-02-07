require 'graphql'

module Nodes
  class PostNode < GraphQL::Node
    desc "A blog post entry"
    field :id
    field :title
    field :content
    field :teaser

    cursor :id

    edges :comments

    edges :likes,
      edge_class_name: "Nodes::ThumbUpEdge",
      node_class_name: "Nodes::ThumbUpNode"

    def teaser
      target.content.length > 10 ? "#{target.content[0..9]}..." : content
    end

    def self.call(argument)
      post = Post.find(argument.to_i)
      self.new(post)
    end
  end

  class CommentNode < GraphQL::Node
    field :id
    field :content

    cursor :id

    def self.call(argument)
      obj = Comment.find(argument)
      self.new(obj)
    end
  end

  # wraps a Like, for testing explicit name
  class ThumbUpNode < GraphQL::Node
    type "Upvote"
    field :id
  end

  class ViewerNode < GraphQL::Node
    field :name

    def name
      "It's you again"
    end

    def cursor
      "viewer"
    end

    def self.call(argument)
      self.new
    end
  end

  class ApplicationCollectionEdge < GraphQL::CollectionEdge
    def apply_calls(items, calls)
      filtered_items = items

      if calls["after"].present?
        filtered_items = filtered_items.select {|i| i.id > calls["after"].to_i }
      end

      if calls["first"].present?
        filtered_items = filtered_items.first(calls["first"].to_i)
      end

      filtered_items
    end
  end

  class CommentsEdge < ApplicationCollectionEdge
    def average_rating
      total_rating = filtered_items.map(&:rating).inject(&:+).to_f
      total_rating / filtered_items.size
    end
  end

  # Wraps Likes, for testing explicit naming
  class ThumbUpEdge < ApplicationCollectionEdge
    def any
      filtered_items.any?
    end
  end
end