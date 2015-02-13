require 'graphql'
require 'support/dummy_app.rb'

module Nodes
  class ApplicationNode < GraphQL::Node
    field :id,
      type: :number
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

  class LetterSelectionField < GraphQL::Types::StringField
    call :from, ->    (prev_value, chars) { prev_value[(chars.to_i)..-1] }
    call :for, ->     (prev_value, chars) { prev_value[0, (chars.to_i)] }
    call :select, ->  (prev_value, from_chars, for_chars) { prev_value[from_chars.to_i, for_chars.to_i] }
    def raw_value
      owner.content
    end
  end

  class DateField < GraphQL::Field
    field_type "Date"
    call :ymd, -> (prev_value) { prev_value.strftime("%Y-%m-%d") }

    def as_json
      if calls.any?
        super
      else
        value.strftime("%b %Y")
      end
    end

    def to_node
      n = DateNode.new(raw_value)
      n.fields = self.fields
      n
    end
  end

  class DateNode < GraphQL::Node
    field :year,  type: :number
    field :month, type: :number
  end

  class PostNode < ApplicationNode
    node_for Post
    desc "A blog post entry"
    field :title,
      type: :string

    field :content,
      type: LetterSelectionField
    field :length,
      type: :number

    field :comments,
      type: :connection

    field :published_at,
      type: DateField

    field :likes,
      type: :connection,
      edge_class_name: "Nodes::ThumbUpEdge",
      node_class_name: "Nodes::ThumbUpNode"

    def length
      target.content.length
    end
  end

  class CommentNode < ApplicationNode
    node_for Comment
    field :content
    field :letters,
      type: LetterSelectionField
  end

  # wraps a Like, for testing explicit name
  class ThumbUpNode < ApplicationNode
    node_for(Like)
    type "Upvote"
  end

  class StupidThumbUpNode < ThumbUpNode
    node_for(Like)
    def id
      target.id.to_s + target.id.to_s
    end
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
    field :count, type: :number
    call :after, -> (prev_items, after) { prev_items.select {|i| i.id > after.to_i } }
    call :first, -> (prev_items, first) { prev_items.first(first.to_i) }
    def count
      items.count
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