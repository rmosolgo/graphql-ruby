---
layout: doc_stub
search: true
title: GraphQL::Schema::PossibleTypes
url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Schema/PossibleTypes
rubydoc_url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/Schema/PossibleTypes
---

Class: GraphQL::Schema::PossibleTypes < Object
Find the members of a union or interface within a given schema. 
(Although its members never change, unions are handled this way to
simplify execution code.) 
Internally, the calculation is cached. It's assumed that schema
members _don't_ change after creating the schema! 
Examples:
# Get an interface's possible types
possible_types = GraphQL::Schema::PossibleTypes(MySchema)
possible_types.possible_types(MyInterface)
# => [MyObjectType, MyOtherObjectType]
Instance methods:
initialize, possible_types

