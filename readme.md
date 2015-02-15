# graphql

[![Build Status](https://travis-ci.org/rmosolgo/graphql-ruby.svg?branch=master)](https://travis-ci.org/rmosolgo/graphql-ruby)
[![Gem Version](https://badge.fury.io/rb/graphql.svg)](https://rubygems.org/gems/graphql)
[![Dependency Status](https://gemnasium.com/rmosolgo/graphql-ruby.svg)](https://gemnasium.com/rmosolgo/graphql-ruby)


Create a GraphQL interface by implementing _nodes_ and _connections_, then running queries.

## To do:

- Make root call API not suck
- Implement calls as arguments
- Implement call argument introspection (wait for spec)
- Allow a default connection class
- Fix naming conflict for calls on fields (if parent has `some_call` and child has `some_call`, use child implementation)
- Do something about the risk of accidently overriding important methods (eg `Field#value`) in custom classes
- For fields that return objects, can they be queried _without_ other fields? Or must they always have fields?

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

- fields, which yield values or other objects
- connections, which expose one-to-many relationships
- `__type__`, which allows introspection on that node type (name, description, fields, edges)
- a `cursor`, which is an opaque string defined by the server.

_(Is the cursor different for different contexts? Or does an object always have the same cursor?)_

Nodes are retrieved by _root calls_. Edges also contain nodes.

### Field

A field belongs to a node. It exposes information about its owner. It may return a scalar or another node (exposing another object or a connection).

Fields are implemented by the server and requested by the client as names inside curly-braces, eg `{ name, id }`.

Fields can be aliased using `as`.

### Call

Calls allow the client to provide specifications along with its request. A call consists of:
- a _name_; and
- any number of _arguments_, wrapped in `()`

Calls can be made:

- at the _root_ of a query, eg `viewer()`
- on _fields_, eg `url.site(www)`, `friends.first(3) as best_pals`

Call arguments are always handled as strings.

Calls can be chained.

### Connections

Connections connect nodes to other nodes. They implement:
- fields of their own, eg `friends { count, page_info { has_next_page }}`
- `__type__`, for introspection on the edge.

To access the member nodes, use `{ edges { node { /* fields */ } }`.

### Context

Context is an implementation-specific object that informs a query about its client. This allows a query to perform authentication, localization, etc.