---
layout: doc_stub
search: true
title: GraphQL::EnumType
url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/EnumType
rubydoc_url: http://www.rubydoc.info/gems/graphql/1.6.0/GraphQL/EnumType
---

Class: GraphQL::EnumType < GraphQL::BaseType
Represents a collection of related values. By convention, enum names
are `SCREAMING_CASE_NAMES`, but other identifiers are supported too.
You can use as return types _or_ as inputs. 
By default, enums are passed to `resolve` functions as the strings
that identify them, but you can provide a custom Ruby value with the
`value:` keyword. 
Examples:
# An enum of programming languages
LanguageEnum = GraphQL::EnumType.define do
name "Languages"
description "Programming languages for Web projects"
value("PYTHON", "A dynamic, function-oriented language")
value("RUBY", "A very dynamic language aimed at programmer happiness")
value("JAVASCRIPT", "Accidental lingua franca of the web")
end
# Using an enum as a return type
field :favoriteLanguage, LanguageEnum, "This person's favorite coding language"
# ...
# In a query:
Schema.execute("{ coder(id: 1) { favoriteLanguage } }")
# { "data" => { "coder" => { "favoriteLanguage" => "RUBY" } } }
# Defining an enum input
field :coders, types[CoderType] do
argument :knowing, types[LanguageType]
resolve ->(obj, args, ctx) {
Coder.where(language: args[:knowing])
}
end
# Using an enum as input
{
# find coders who know Python and Ruby
coders(knowing: [PYTHON, RUBY]) {
name
hourlyRate
}
}
# Enum whose values are different in Ruby-land
GraphQL::EnumType.define do
# ...
# use the `value:` keyword:
value("RUBY", "Lisp? Smalltalk?", value: :rb)
end
# Now, resolve functions will receive `:rb` instead of `"RUBY"`
field :favoriteLanguage, LanguageEnum
resolve ->(obj, args, ctx) {
args[:favoriteLanguage] # => :rb
}
# Enum whose values are different in ActiveRecord-land
class Language < ActiveRecord::BaseType
enum language: {
rb: 0
}
end
# Now enum type should be defined as
GraphQL::EnumType.define do
# ...
# use the `value:` keyword:
value("RUBY", "Lisp? Smalltalk?", value: 'rb')
end
Instance methods:
add_value, coerce_non_null_input, coerce_result, initialize,
initialize_copy, kind, to_s, validate_non_null_input, values,
values=

