---
layout: doc_stub
search: true
title: GraphQL::UnionType
url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/UnionType
rubydoc_url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/UnionType
---

Class: GraphQL::UnionType < GraphQL::BaseType
A Union is is a collection of object types which may appear in the
same place. 
The members of a union are declared with `possible_types`. 
A union itself has no fields; only its members have fields. So, when
you query, you must use fragment spreads to access fields. 
Examples:
# A union of object types
MediaUnion = GraphQL::UnionType.define do
name "Media"
description "Media objects which you can enjoy"
possible_types [AudioType, ImageType, VideoType]
end
# Querying for fields on union members
{
searchMedia(name: "Jens Lekman") {
... on Audio { name, duration }
... on Image { name, height, width }
... on Video { name, length, quality }
}
}
Instance methods:
include?, initialize, initialize_copy, kind, possible_types,
possible_types=

