# graphql

[![Build Status](https://travis-ci.org/rmosolgo/graphql-ruby.svg?branch=master)](https://travis-ci.org/rmosolgo/graphql-ruby)

- Parser & tranform from [parslet](http://kschiess.github.io/parslet/)
- Your app can implement nodes
- You can pass strings to `GraphQL::Query` and execute them with your nodes

__Nodes__ provide information to queries by mapping to application objects (via `.call` and `.field_reader`) or implementing fields themselves (eg `Nodes::PostNode#teaser`, `Nodes::ViewerNode`).

__Edges__ handle node-to-node relationships. Calls are provided to `#apply_calls(items, call_hash)` as a hash of `callname => argument` pairs. Your app decides which calls to handle and how to handle them.


## To do:

- Better class inference. Declaring edge classes is stupid.
- How to authenticate?
- What do graphql mutation queries even look like?

## For example

See [`/spec/support/dummy_app/nodes.rb`](https://github.com/rmosolgo/graphql/blob/master/spec/support/nodes.rb) for node & edge examples.

You could implement nodes that map to objects in a Rails app.

![gql](https://cloud.githubusercontent.com/assets/2231765/6055402/58ea2efc-acb3-11e4-95ea-0a22af9737d3.gif)
