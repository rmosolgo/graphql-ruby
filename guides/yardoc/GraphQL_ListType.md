---
layout: doc_stub
search: true
title: GraphQL::ListType
url: http://www.rubydoc.info/gems/graphql/GraphQL/ListType
rubydoc_url: http://www.rubydoc.info/gems/graphql/GraphQL/ListType
---

Class: GraphQL::ListType < GraphQL::BaseType
A list type modifies another type. 
List types can be created with the type helper (`types[InnerType]`)
or BaseType#to_list_type (`InnerType.to_list_type`) 
For return types, it says that the returned value will be a list of
the modified. 
For input types, it says that the incoming value will be a list of
the modified type. 
Given a list type, you can always get the underlying type with
#unwrap. 
Examples:
# A field which returns a list of items
field :items, types[ItemType]
# or
field :items, ItemType.to_list_type
# A field which accepts a list of strings
field :newNames do
# ...
argument :values, types[types.String]
# or
argument :values, types.String.to_list_type
end
Includes:
GraphQL::BaseType::ModifiesAnotherType
Instance methods:
coerce_non_null_input, coerce_result, initialize, kind, to_s,
validate_non_null_input

