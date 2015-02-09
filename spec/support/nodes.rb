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

  class LetterSelectionField < GraphQL::Field
    call :from, ->    (prev_value, chars) { prev_value[(chars.to_i)..-1] }
    call :for, ->     (prev_value, chars) { prev_value[0, (chars.to_i)] }
    call :select, ->  (prev_value, from_chars, for_chars) { prev_value[from_chars.to_i, for_chars.to_i] }
    def raw_value
      owner.content
    end
  end

  class CommentNode < GraphQL::Node
    field :id
    field :content
    field :letters, extends: LetterSelectionField

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

    def self.call
      self.new
    end
  end

  class ContextNode < GraphQL::Node
    field :person_name

    def person_name
      context[:person_name]
    end

    def cursor
      "context"
    end

    def self.call
      self.new
    end
  end

  class ApplicationEdge < GraphQL::Edge
    field :count

    def apply_calls(items, calls)
      filtered_items = items

      if calls["after"].present?
        filtered_items = filtered_items.select {|i| i.id > calls["after"].first.to_i }
      end

      if calls["first"].present?
        filtered_items = filtered_items.first(calls["first"].first.to_i)
      end

      filtered_items
    end
  end

  class CommentsEdge < ApplicationEdge
    field :viewer_name_length
    field :average_rating

    # just to test context:
    def viewer_name_length
      context[:person_name].length
    end

    def average_rating
      total_rating = filtered_items.map(&:rating).inject(&:+).to_f
      total_rating / filtered_items.size
    end
  end

  # Wraps Likes, for testing explicit naming
  class ThumbUpEdge < ApplicationEdge
    field :any

    def any
      filtered_items.any?
    end
  end
end