---
layout: doc_stub
search: true
title: GraphQL::Relay::RangeAdd
url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Relay/RangeAdd
rubydoc_url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Relay/RangeAdd
---

Class: GraphQL::Relay::RangeAdd < Object
This provides some isolation from `GraphQL::Relay` internals. 
Given a list of items and a new item, it will provide a connection
and an edge. 
The connection doesn't receive outside arguments, so the list of
items should be ordered and paginated before providing it here. 
Examples:
# Adding a comment to list of comments
post = Post.find(args[:postId])
comments = post.comments
new_comment = comments.build(body: args[:body])
new_comment.save!
range_add = GraphQL::Relay::RangeAdd.new(
parent: post,
collection: comments,
item: new_comment,
context: ctx,
)
response = {
post: post,
commentsConnection: range_add.connection,
newCommentEdge: range_add.edge,
}
Instance methods:
initialize

