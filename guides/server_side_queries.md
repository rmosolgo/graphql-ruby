# Server-Side Queries

`GraphQL::QueryCache` allows you to load queries on the server, then invoke them by name in the client. This gives you a few benefits: you don't have to re-parse & re-validate the same query and you don't have to send the query body over the network. Instead, run the _same_ query with _new_ variables & context.

## Caching Queries

Store queries in a query cache with {Schema#cache}:

```ruby
MySchema.cache("
query getItem($id: Int!) {
  item(id: $id) {
    name,
    price,
    reviews(first: 3) {
      user { name }
      content
    }
  }
}
")
```

## Invoking stored queries

Invoke a query by passing its _operation name_, but not a query string.

```ruby
MySchema.execute(operation_name: "getItem", variables: {"id" => 3})
# {
#  "data" => {
#    "item" => { ... }
#   }
# }
```
