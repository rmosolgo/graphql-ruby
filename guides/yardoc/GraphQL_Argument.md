---
layout: doc_stub
search: true
title: GraphQL::Argument
url: http://www.rubydoc.info/gems/graphql/GraphQL/Argument
rubydoc_url: http://www.rubydoc.info/gems/graphql/GraphQL/Argument
---

Class: GraphQL::Argument < Object
Used for defined arguments (Field, InputObjectType) 
#name must be a String. 
Examples:
# defining an argument for a field
GraphQL::Field.define do
# ...
argument :favoriteFood, types.String, "Favorite thing to eat", default_value: "pizza"
end
# defining an argument for an {InputObjectType}
GraphQL::InputObjectType.define do
argument :newName, !types.String
end
# defining an argument with a `prepare` function
GraphQL::Field.define do
argument :userId, types.ID, prepare: ->(userId) do
User.find_by(id: userId)
end
end
# returning an {ExecutionError} from a `prepare` function
GraphQL::Field.define do
argument :date do
type !types.String
prepare ->(date) do
return GraphQL::ExecutionError.new("Invalid date format") unless DateValidator.valid?(date)
Time.zone.parse(date)
end
end
end
Includes:
GraphQL::Define::InstanceDefinable
Class methods:
from_dsl
Instance methods:
default_value?, expose_as, initialize, initialize_copy, prepare,
prepare=

