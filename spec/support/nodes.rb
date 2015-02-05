module Nodes
  class PostNode < GraphQL::Node
    field_reader :id, :title, :content
    cursor :id

    edges :comments,
      collection_class_name: "Nodes::ApplicationCollectionEdge",
      edge_class_name: "Nodes::CommentNode"

    def teaser
      content.length > 10 ? "#{content[0..9]}..." : content
    end

    def self.call(argument)
      post = Post.find(argument.to_i)
      self.new(post)
    end
  end

  class CommentNode < GraphQL::Node
    field_reader :id, :post, :content
    cursor :id

    def self.call(argument)
      obj = Comment.find(argument)
      self.new(obj)
    end
  end

  class ViewerNode < GraphQL::Node
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
end