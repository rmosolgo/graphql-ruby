---
layout: doc_stub
search: true
title: GraphQL::Schema::Printer
url: http://www.rubydoc.info/gems/graphql/GraphQL/Schema/Printer
rubydoc_url: http://www.rubydoc.info/gems/graphql/GraphQL/Schema/Printer
---

Class: GraphQL::Schema::Printer < Object
Used to convert your GraphQL::Schema to a GraphQL schema string 
Examples:
# print your schema to standard output (via helper)
MySchema = GraphQL::Schema.define(query: QueryType)
puts GraphQL::Schema::Printer.print_schema(MySchema)
# print your schema to standard output
MySchema = GraphQL::Schema.define(query: QueryType)
puts GraphQL::Schema::Printer.new(MySchema).print_schema
# print a single type to standard output
query_root = GraphQL::ObjectType.define do
name "Query"
description "The query root of this schema"
field :post do
type post_type
resolve ->(obj, args, ctx) { Post.find(args["id"]) }
end
end
post_type = GraphQL::ObjectType.define do
name "Post"
description "A blog post"
field :id, !types.ID
field :title, !types.String
field :body, !types.String
end
MySchema = GraphQL::Schema.define(query: query_root)
printer = GraphQL::Schema::Printer.new(MySchema)
puts printer.print_type(post_type)
Class methods:
print_introspection_schema, print_schema
Instance methods:
build_blacklist, initialize, print_directive, print_schema,
print_schema_definition, print_type

