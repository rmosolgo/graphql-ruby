---
layout: doc_stub
search: true
title: GraphQL::Function
url: http://www.rubydoc.info/gems/graphql/GraphQL/Function
rubydoc_url: http://www.rubydoc.info/gems/graphql/GraphQL/Function
---

Class: GraphQL::Function < Object
A reusable container for field logic, including arguments, resolve,
return type, and documentation. 
Class-level values defined with the DSL will be inherited, so
{GraphQL::Function}s can extend one another. 
It's OK to override the instance methods here in order to customize
behavior of instances. 
Examples:
# A reusable GraphQL::Function attached as a field
class FindRecord < GraphQL::Function
attr_reader :type
def initialize(model:, type:)
@model = model
@type = type
end
argument :id, GraphQL::ID_TYPE
def call(obj, args, ctx)
@model.find(args.id)
end
end
QueryType = GraphQL::ObjectType.define do
name "Query"
field :post, function: FindRecord.new(model: Post, type: PostType)
field :comment, function: FindRecord.new(model: Comment, type: CommentType)
end
Class methods:
argument, arguments, complexity, deprecation_reason, description,
inherited_value, own_arguments, parent_function?, type, types
Instance methods:
arguments, call, complexity, deprecation_reason, description, type

