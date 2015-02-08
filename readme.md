# graphql

[![Build Status](https://travis-ci.org/rmosolgo/graphql-ruby.svg?branch=master)](https://travis-ci.org/rmosolgo/graphql-ruby)
[![Gem Version](https://badge.fury.io/rb/graphql.svg)](https://rubygems.org/gems/graphql)

Create a GraphQL interface by implementing _nodes_ and _edges_, then running queries.

__Nodes__ provide information to queries by mapping to application objects via `.call` and `.field_reader`. They can wrap existing objects (like models) or provide data by implementing methods.

__Edges__ handle node-to-node relationships. Calls are provided to `#apply_calls(items, call_hash)` as a hash of `callname => argument` pairs. Your app decides which calls to handle and how to handle them.

__Queries__ are made with `GraphQL::Query.new(query_string, namespace:)`. Use `Query#as_json` to get the result of a query.

## To do:

- Implement type & field documentation
- Implement call introspection
- Implement calls on fields
- Implement root with multiple keys (eg `node(4,6) => { "4": {}, "6": {}`)
- Test mutations
- Implement `page_info`
- Implement calls as arguments
- Syntax for aliasing edges?

## For example

See [`/spec/support/dummy_app/nodes.rb`](https://github.com/rmosolgo/graphql/blob/master/spec/support/nodes.rb) for node & edge examples.

You could implement nodes that map to objects in a Rails app.

![gql](https://cloud.githubusercontent.com/assets/2231765/6055402/58ea2efc-acb3-11e4-95ea-0a22af9737d3.gif)


## About this project

GraphQL was recently announced by Facebook as their prefered HTTP API. From various sources, this is what I have learned about it.

__Contents__

- [Definition](#definition)
- [Examples](#examples)
- [Syntax](#syntax)

## Definition

GraphQL is:
- a text interface for client-server communication.
- a means of exposing your application. Since it's implemented by your application, it may expose data from storage or other application-specific values.
- backend- and language-agnostic.

To serve GraphQL, a server implements a single endpoint which accepts queries and returns JSON responses.

## Examples

### Retrieving data

```
node(4, 6) {
  id,
  url.site(mobile) as mobile_url,
  url.site(www) as www_url,
  friends.orderby(name).first(1) {
   count,
   edges {
     cursor,
     node {
       id,
       name
    }
   }
  }
}
```

```js
{
 "4": {
    "id" : 4,
    "mobile_url" : "https://m.facebook.com/4",
    "www_url" : "https://www.facebook.com/4",
    "friends" : {
      "count" : 1000,
      "edges" : [
        {
          "cursor": "6",
          "node": {
            "id": 6,
            "name" : "Your pal"
          }
        }
      ]
    },
 "6": { /* similar structure as above */ }
 }
```

### Mutations

Mutation queries are root calls with side-effects. They expose fields that may have changed as a result of the mutation.

Client tokens allow the client to make optimistic updates, then revert if the operation fails.

```
page_like({
  "client_token": "4001",
  "id": 1234
 }) {
 page {
  likes,
  liked_by_viewer
 }
}
```

```js
{
  "1234": {
    "likes": 41,
    "liked_by_viewer": true
  },
  "client_token": "4001"
}
```

## Syntax

### Node

Nodes map to objects in your application (maybe something in your database, maybe some other object like `current_user`). They have:

- fields, which yield values
- edges, which expose one-to-many relationships
- `__type__`, which allows introspection on that node type (name, description, fields, edges)
- a `cursor`, which is an opaque string defined by the server.

_(Is the cursor different for different contexts? Or does an object always have the same cursor?)_

Nodes are retrieved by _root calls_. Edges also contain nodes.

### Field

A field belongs to a node or an edge. It exposes information about its owner.

Fields are implemented by the server and requested by the client as names inside curly-braces, eg `{ name, id }`.

Fields can be aliased using `as`.

### Call

Calls allow the client to provide specifications along with its request. A call consists of:
- a _name_; and
- any number of _arguments_, wrapped in `()`

Calls can be made:

- at the _root_ of a query, eg `viewer()`
- on _fields_, eg `url.site(www)`
- on _edges_, eg `friends.orderby(name, birthdate).first(3)`

Calls can be chained.

### Edge

Edges connect nodes to other nodes. They implement:
- calls, eg `friends.first(1)`
- fields of their own, eg `friends { count, page_info { has_next_page }}`
- `__type__`, for introspection on the edge.

To access the member nodes, use `{ edges { node { /* fields */ } }`.

Edges can be nested to any depth.

### Context

Context is an implementation-specific object that informs a query about its client. This allows a query to perform authentication, localization, etc.