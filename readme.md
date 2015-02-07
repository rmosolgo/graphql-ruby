# graphql

[![Build Status](https://travis-ci.org/rmosolgo/graphql-ruby.svg?branch=master)](https://travis-ci.org/rmosolgo/graphql-ruby)
[![Gem Version](https://badge.fury.io/rb/graphql.svg)](http://badge.fury.io/rb/graphql)

Create a GraphQL interface by implementing _nodes_ and _edges_, then running queries.

__Nodes__ provide information to queries by mapping to application objects via `.call` and `.field_reader`. They can wrap existing objects (like models) or provide data by implementing methods.

__Edges__ handle node-to-node relationships. Calls are provided to `#apply_calls(items, call_hash)` as a hash of `callname => argument` pairs. Your app decides which calls to handle and how to handle them.

__Queries__ are made with `GraphQL::Query.new(query_string, namespace:)`. Use `Query#as_json` to get the result of a query.

## To do:

- Implement type & field documentation
- Implement calls on fields
- Root with multiple keys
- Implement `context`
- Test mutations
- Implement aliases
- Implement `page_info`
- Implement calls as arguments

## For example

See [`/spec/support/dummy_app/nodes.rb`](https://github.com/rmosolgo/graphql/blob/master/spec/support/nodes.rb) for node & edge examples.

You could implement nodes that map to objects in a Rails app.

![gql](https://cloud.githubusercontent.com/assets/2231765/6055402/58ea2efc-acb3-11e4-95ea-0a22af9737d3.gif)
