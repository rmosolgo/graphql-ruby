class InadequateRecordBase
  def initialize(attributes={})
    attributes.each do |key, value|
      self.send("#{key}=", value)
    end
  end

  def destroy
    self.class.all.delete(self)
  end

  class << self
    attr_accessor :_objects
    def all
      @_objects ||= []
    end

    def find(id)
      all.find { |object| object.id.to_s == id.to_s } || raise("Failed to find #{name} => #{id}")
    end

    def where(query={})
      result = []
      all.each do |object|
        match = true

        query.each do |key, value|
          if object.send(key) != value
            match = false
          end
        end

        result << object if match
      end
      result
    end

    def create(attributes)
      @next_id ||= 0
      attributes[:id] ||= @next_id += 1
      instance = self.new(attributes)
      all << instance
      instance
    end
  end
end

class Post < InadequateRecordBase
  attr_accessor :id, :title, :content, :published_at

  def comments
    Comment.where(post_id: id)
  end

  def likes
    Like.where(post_id: id)
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
