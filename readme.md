# graphql

- Parser & tranform from [parslet](http://kschiess.github.io/parslet/)
- Your app can implement nodes
- You can pass strings to `GraphQL::Query` and execute them with your nodes

See `/spec/support/dummy_app/nodes.rb` for node examples

__Nodes__ provide information to queries by mapping to application objects (via `.call` and `field_reader`) or implementing fields themselves (eg `Nodes::PostNode#teaser`).

__Edges__ handle node-to-node relationships.


## To do:

- Better class inference. Declaring edge classes is stupid.
- How to authenticate?
- What do graphql mutation queries even look like?