---
layout: doc_stub
search: true
title: GraphQL::ObjectType
url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/ObjectType
rubydoc_url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/ObjectType
---

Class: GraphQL::ObjectType < GraphQL::BaseType
This type exposes fields on an object. 
Examples:
# defining a type for your IMDB clone
MovieType = GraphQL::ObjectType.define do
name "Movie"
description "A full-length film or a short film"
interfaces [ProductionInterface, DurationInterface]
field :runtimeMinutes, !types.Int, property: :runtime_minutes
field :director, PersonType
field :cast, CastType
field :starring, types[PersonType] do
argument :limit, types.Int
resolve ->(object, args, ctx) {
stars = object.cast.stars
args[:limit] && stars = stars.limit(args[:limit])
stars
}
end
end
Direct Known Subclasses:
Relay::Edge
Instance methods:
all_fields, get_field, implements, initialize, initialize_copy,
interface_fields, interfaces, interfaces=, kind, load_interfaces,
normalize_interfaces

