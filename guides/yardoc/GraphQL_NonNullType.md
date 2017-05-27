---
layout: doc_stub
search: true
title: GraphQL::NonNullType
url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/NonNullType
rubydoc_url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/NonNullType
---

Class: GraphQL::NonNullType < GraphQL::BaseType
A non-null type modifies another type. 
Non-null types can be created with `!` (`InnerType!`) or
BaseType#to_non_null_type (`InnerType.to_non_null_type`) 
For return types, it says that the returned value will _always_ be
present. 
(If the application fails to return a value, InvalidNullError will
be passed to Schema#type_error.) 
For input types, it says that the incoming value _must_ be provided
by the query. 
(If a value isn't provided, Query::VariableValidationError will be
raised). 
Given a non-null type, you can always get the underlying type with
#unwrap. 
Examples:
# A field which _always_ returns an error
field :items, !ItemType
# or
field :items, ItemType.to_non_null_type
# A field which _requires_ a string input
field :newNames do
# ...
argument :values, !types.String
# or
argument :values, types.String.to_non_null_type
end
Includes:
GraphQL::BaseType::ModifiesAnotherType
Extended by:
Forwardable
Instance methods:
initialize, kind, to_s, valid_input?, validate_input

