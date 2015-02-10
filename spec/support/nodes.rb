require 'graphql'

module Nodes
  class ApplicationNode < GraphQL::Node
    field :id
    cursor :id

    class << self
      attr_accessor :model_class
      def node_for(m_class)
        @model_class = m_class
      end

      def call(*ids)
        ids = ids.map(&:to_i)
        items = model_class.all.select { |x| ids.include?(x.id) }
        items.map { |x| self.new(x) }
      end
    end
  end

  class PostNode < ApplicationNode
    node_for Post
    desc "A blog post entry"
    field :title
    field :content
    field :teaser

    edges :comments

    edges :likes,
      edge_class_name: "Nodes::ThumbUpEdge",
      node_class_name: "Nodes::ThumbUpNode"

    def teaser
      target.content.length > 10 ? "#{target.content[0..9]}..." : content
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

  class CommentNode < ApplicationNode
    node_for Comment
    field :content
    field :letters, extends: LetterSelectionField
  end

  # wraps a Like, for testing explicit name
  class ThumbUpNode < ApplicationNode
    node_for(Like)
    type "Upvote"
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
    call :after, -> (prev_items, after) { prev_items.select {|i| i.id > after.to_i } }
    call :first, -> (prev_items, first) { prev_items.first(first.to_i) }
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