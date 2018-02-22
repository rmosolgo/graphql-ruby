---
layout: guide
search: true
section: Type Definitions
title: Lists
desc: Ordered lists containing other types
index: 6
---

GraphQL has _list types_ which are ordered lists containing items of other types. The following examples use the [GraphQL Schema Definition Language](http://graphql.org/learn/schema/#type-language) (SDL).

Fields may return a single scalar value (eg `String`), or a _list_ of scalar values (eg, `[String]`, a list of strings):

```ruby
type Spy {
  # This spy's real name
  realName: String!
  # Any other names that this spy goes by
  aliases: [String!]
}
```

Fields may also return lists of other types as well:

```ruby
enum PostCategory {
  SOFTWARE
  UPHOLSTERY
  MAGIC_THE_GATHERING
}

type BlogPost {
  # Zero or more categories this post belongs to
  categories: [PostCategory!]
  # Other posts related to this one
  relatedPosts: [BlogPost!]
}
```

Inputs may also be lists. Arguments can accept list types, for example:

```ruby
type Query {
  # Return the latest posts, filtered by `categories`
  posts(categories: [PostCategory!]): [BlogPost!]
}
```

When GraphQL is sent and received with JSON, GraphQL lists are expressed in JSON arrays.

## List Types in Ruby

To define a list type in Ruby use `[...]` (a Ruby array with one member, the inner type). For example:

```ruby
# A field returning a list type:
# Equivalent to `aliases: [String!]` above
field :aliases, [String], null: true

# An argument which accepts a list type:
argument :categories, [Types::PostCategory], required: false
```

For input, GraphQL lists are converted to Ruby arrays.

For fields that return list types, any object responding to `#each` may be returned. It will be enumerated as a GraphQL list.

To define lists where `nil` may be a member of the list, use `null: true` in the definition array, for example:

```ruby
# Equivalent to `previousEmployers: [Employer]!`
field :previous_employers, [Types::Employer, null: true], "Previous employers; `null` represents a period of self-employment or unemployment" null: false
```
