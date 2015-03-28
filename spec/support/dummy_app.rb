require_relative './inadequate_record_base'

class Post < InadequateRecordBase
  attr_accessor :id, :title, :content, :published_at
  def comments
    Comment.where(post_id: id)
  end
  def likes
    Like.where(post_id: id)
  end

  class Album < InadequateRecordBase
    attr_accessor :id, :post_id, :title
    def post
      Post.find(post_id)
    end
    def comments
      post.comments
    end
  end
end

class Comment < InadequateRecordBase
  attr_accessor :id, :post_id, :content, :rating
  def post
    Post.find(post_id)
  end
end

class Like < InadequateRecordBase
  attr_accessor :id, :post_id
  def post
    Post.find(post_id)
  end
end

class Context
  attr_reader :person_name
  def initialize(person_name:)
    @person_name = person_name
  end
end
