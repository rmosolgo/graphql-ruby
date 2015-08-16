# graphql-relay

## UNDER CONSTRUCTION 👷🏽🚧

Helpers for using [`graphql`](https://github.com/rmosolgo/graphql-ruby) with Relay.

## Todo

- Connections
  - [x] arguments (Object definition `connection` helper)
  - [x] connection type for type (`ConnectionType#connection_class`)
  - [ ] Connection classes
    - [x] ArrayConnection
    - [ ] HasManyConnection

- Object Identification
  - [x] Node-related types
      - [x] NodeInterface (returned from `Node.create`)
      - [x] NodeField (returned from `Node.create`)
  - [x] toGlobalId, fromGlobalId (`Node.from_global_id`, `Node.to_global_id`)
  - [x] globalIdField (`field :id, field: GlobalIdField.new("TypeName")`)

- Mutations
  - [ ] Accept inputs, outputs and resolution
  - [ ] Return a field

## More Resources

- [`graphql`](https://github.com/rmosolgo/graphql-ruby) Ruby gem
- [`graphql-relay-js`](https://github.com/graphql/graphql-relay-js) JavaScript helpers for GraphQL and Relay
