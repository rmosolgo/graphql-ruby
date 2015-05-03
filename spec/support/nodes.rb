require 'graphql'
require 'support/dummy_app.rb'

module Nodes
  class ApplicationNode < GraphQL::Node
    field.number(:id)
    cursor :id

    class << self
      attr_accessor :model_class
      def node_for(m_class)
        @model_class = m_class
      end
    end
  end


  class ApplicationConnection < GraphQL::Connection
    type :connection
    call :first, -> (prev_items, first) { prev_items.first(first.to_i) }
    call :after, -> (prev_items, after) { prev_items.select {|i| i.id > after.to_i } }

    field.number(:count)
    field.boolean(:any)

    def count
      target.count
    end

    def any
      target.any?
    end
  end

  class CommentsConnection < ApplicationConnection
    type :comments
    field.number :viewer_name_length
    field.number :average_rating

    # just to test context:
    def viewer_name_length
      context.person_name.length
    end

    def average_rating
      total_rating = target.map(&:rating).inject(&:+).to_f
      total_rating / target.size
    end
  end

  class GraphQL::Types::DateTimeType
    call :minus_days, -> (prev_value, minus_days) { prev_value - minus_days.to_i }
  end

  class PostNode < ApplicationNode
    node_for Post
    exposes "Post"
    desc "A blog post entry"

    field.string(:title)
    field.letter_selection(:content)
    field.number(:length)
    field.comments(:comments)
    field.date_time(:published_at)
    field.connection(:likes)

    def length
      target.content.length
    end
  end

  class CommentNode < ApplicationNode
    node_for Comment
    exposes "Comment"
    desc("Comment on a blog post")
    field.string(:content)
    field.letter_selection(:letters)
    field.post(:post)

    def letters; content; end
  end

  class AlbumNode < ApplicationNode
    desc "Photos to accompany a post"
    node_for Post::Album
    # Schema validation test, can it handle:
    # - nested exposes name
    # - field name inferred from field type
    exposes("Post::Album")
    field.string(:title)
    field.comments
    field.post
  end

  # wraps a Like, for testing explicit name
  class ThumbUpNode < ApplicationNode
    node_for(Like)
    exposes "Like"
    type "upvote"
    desc("A show of support for a post")
    field.number :post_id
    field.number :person_id
    def id
      target.id.to_s + target.id.to_s
    end
  end

  class ContextNode < GraphQL::Node
    exposes "Context"
    desc("A request context")
    field.string(:person_name)
    field.boolean(:present)

    def cursor
      "context"
    end

    def present
      true
    end
  end

  class LetterSelectionType < GraphQL::Node
    type :letter_selection
    call :from, ->    (prev_value, chars) { prev_value[(chars.to_i)..-1] }
    call :for, ->     (prev_value, chars) { prev_value[0, (chars.to_i)] }
    call :select, ->  (prev_value, from_chars, for_chars) { prev_value[from_chars.to_i, for_chars.to_i] }
    def as_result
      apply_calls(target)
    end
  end

  class FindCall < GraphQL::RootCall
    abstract!
    argument.number("ids", any_number: true)
    def execute(*ids)
      model_class = model_type
      items = ids.map { |id| model_class.find(id.to_i) }
    end
  end

  class PostCall < FindCall
    returns :post
    def model_type
      Post
    end
  end

  class CommentCall < FindCall
    returns :comment
    def model_type
      Comment
    end
  end

  class ThumbUpCall < FindCall
    returns :thumb_up
    def model_type
      Like
    end
  end

  class ContextCall < GraphQL::RootCall
    returns :context
    def execute
      context
    end
  end

  class LikePostCall < GraphQL::RootCall
    indentifier "upvote_post"
    returns :post, :upvote, :context

    argument.object("post_data")
    argument.number("person_id")


    def execute(post_data, person_id)
      post_id = post_data["id"]
      like = Like.create(post_id: post_id, person_id: person_id)
      {
        post: Post.find(post_id),
        upvote: like,
        context: context,
      }
    end
  end
end