# graphql <img src="https://cloud.githubusercontent.com/assets/2231765/9094460/cb43861e-3b66-11e5-9fbf-71066ff3ab13.png" height="40" alt="graphql-ruby"/>

[![Build Status](https://travis-ci.org/rmosolgo/graphql-ruby.svg?branch=master)](https://travis-ci.org/rmosolgo/graphql-ruby)
[![Gem Version](https://badge.fury.io/rb/graphql.svg)](https://rubygems.org/gems/graphql)
[![Code Climate](https://codeclimate.com/github/rmosolgo/graphql-ruby/badges/gpa.svg)](https://codeclimate.com/github/rmosolgo/graphql-ruby)
[![Test Coverage](https://codeclimate.com/github/rmosolgo/graphql-ruby/badges/coverage.svg)](https://codeclimate.com/github/rmosolgo/graphql-ruby)
[![built with love](https://cloud.githubusercontent.com/assets/2231765/6766607/d07992c6-cfc9-11e4-813f-d9240714dd50.png)](http://rmosolgo.github.io/react-badges/)

A Ruby implementation of [GraphQL](http://graphql.org/).

 - [Website](https://rmosolgo.github.io/graphql-ruby)
 - [API Documentation](http://www.rubydoc.info/github/rmosolgo/graphql-ruby)

## Installation

Install from RubyGems by adding it to your `Gemfile`, then bundling.

```ruby
# Gemfile
gem 'graphql'
```

```
$ bundle install
```

## Overview

#### Declare types & build a schema

```ruby
# Declare a type...
PostType = GraphQL::ObjectType.define do
  name "Post"
  description "A blog post"

  field :id, !types.ID
  field :title, !types.String
  field :body, !types.String
  field :comments, types[!CommentType]
end

# ...and a query root
QueryType = GraphQL::ObjectType.define do
  name "Query"
  description "The query root of this schema"

  field :post do
    type PostType
    argument :id, !types.ID
    resolve ->(obj, args, ctx) { Post.find(args["id"]) }
  end
end

# Then create your schema
Schema = GraphQL::Schema.define do
  query QueryType
  max_depth 8
end
```

#### Execute queries

Execute GraphQL queries on a given schema, from a query string.

```ruby
result_hash = Schema.execute(query_string)
# {
#   "data" => {
#     "post" => {
#        "id" => 1,
#        "title" => "GraphQL is nice"
#     }
#   }
# }
```

#### Use with Relay

If you're building a backend for [Relay](http://facebook.github.io/relay/), you'll need:

- A JSON dump of the schema, which you can get by sending [`GraphQL::Introspection::INTROSPECTION_QUERY`](https://github.com/rmosolgo/graphql-ruby/blob/master/lib/graphql/introspection/introspection_query.rb)
- Relay-specific helpers for GraphQL, see [`GraphQL::Relay`](http://www.rubydoc.info/github/rmosolgo/graphql-ruby/file/guides/relay.md)

## Goals

- Implement the GraphQL spec & support a Relay front end
- Provide idiomatic, plain-Ruby API with similarities to reference implementation where possible
- Support Ruby on Rails and Relay

## Getting Involved

- __Say hi & ask questions__ in the [#ruby channel on Slack](https://graphql-slack.herokuapp.com/) or [on Twitter](https://twitter.com/rmosolgo)!
- __Report bugs__ by posting a description, full stack trace, and all relevant code in a  [GitHub issue](https://github.com/rmosolgo/graphql-ruby/issues).
- __Features & patches__ are welcome! Consider discussing it in an [issue](https://github.com/rmosolgo/graphql-ruby/issues) or in the [#ruby channel on Slack](https://graphql-slack.herokuapp.com/) to make sure we're on the same page.
- __Run the tests__ with `rake test` or start up guard with `bundle exec guard`.
- __Build the site__ with `rake site:serve`, then visit `localhost:4000`.

## Related Projects

### Code

- `graphql-ruby` + Rails demo ([src](https://github.com/rmosolgo/graphql-ruby-demo) / [heroku](http://graphql-ruby-demo.herokuapp.com))
- [`graphql-batch`](https://github.com/shopify/graphql-batch), a batched query execution strategy
- [`graphql-libgraphqlparser`](https://github.com/rmosolgo/graphql-libgraphqlparser-ruby), bindings to [libgraphqlparser](https://github.com/graphql/libgraphqlparser), a C-level parser.

### Blog Posts

-  Building a blog in GraphQL and Relay on Rails [Introduction](https://medium.com/@gauravtiwari/graphql-and-relay-on-rails-getting-started-955a49d251de), [Part 1]( https://medium.com/@gauravtiwari/graphql-and-relay-on-rails-creating-types-and-schema-b3f9b232ccfc), [Part 2](https://medium.com/@gauravtiwari/graphql-and-relay-on-rails-first-relay-powered-react-component-cb3f9ee95eca)
- https://medium.com/@khor/relay-facebook-on-rails-8b4af2057152
- https://blog.jacobwgillespie.com/from-rest-to-graphql-b4e95e94c26b#.4cjtklrwt
- http://mgiroux.me/2015/getting-started-with-rails-graphql-relay/
- http://mgiroux.me/2015/uploading-files-using-relay-with-rails/

## To Do

- StaticValidation improvements ([in progress](https://github.com/rmosolgo/graphql-ruby/pull/268))
  - Use catch-all type/field/argument definitions instead of terminating traversal
  - Reduce ad-hoc traversals?
  - Validators are order-dependent, is this a smell?
  - Tests for interference between validators are poor
  - Maybe this is a candidate for a rewrite?
- Add Rails-y argument validations, eg `less_than: 100`, `max_length: 255`, `one_of: [...]`
  - Must be customizable
- Relay:
  - Reduce duplication in ArrayConnection / RelationConnection
  - Improve API for creating edges (better RANGE_ADD support)
  - If the new edge isn't a member of the connection's objects, raise a nice error
- Missing Enum value should raise a descriptive error, not "key not found"
- `args` should whitelist keys -- if you request a key that isn't defined for the field, it should 💥
- Fix middleware ([discussion](https://github.com/rmosolgo/graphql-ruby/issues/186))
  - Handle out-of-bounds lookup, eg `graphql-batch`
  - Handle non-serial execution, eg `@defer`
- Support non-instance-eval `.define`, eg `.define { |defn| ... }`
- First-class promise support ([discussion](https://github.com/rmosolgo/graphql-ruby/issues/274))
  - like `graphql-batch` but more local
  - support promises in connection resolves
- Add immutable transformation API to AST
  - Support working with AST as data
  - Adding fields to selections (`__typename` can go anywhere, others are type-specific)
  - Renaming fragments from local names to unique names
- Support AST subclasses? This would be hard, I think classes are used as hash keys in many places.
- Support object deep-copy (schema, type, field, argument)? To support multiple schemas based on the same types. ([discussion](https://github.com/rmosolgo/graphql-ruby/issues/269))
- Improve the website
  - Feature the logo in the header
  - Split `readme.md` into `index.md` (a homepage with code samples) and a technical readme (how to install, link to homepage)
  - Move "Related projects" to a guide
  - Revisit guides, maybe split them into smaller, more specific pages
  - Put guide titles into the `<title />`
- Document encrypted & versioned cursors
