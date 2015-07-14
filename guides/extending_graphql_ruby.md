# Extending `graphql-ruby`

`graphql-ruby` ships with many loosely-coupled components which may be swapped out for custom ones. At create-time, `GraphQL::Schema` validates itself to ensure all parts are compliant.

For example, any object may be an object type. It must implement:

- `#name`
- `#description`
- `#fields` (hash of `String => Field` pairs)
- `#interfaces` (array)

There are similar requirements for fields, unions, interfaces and input values. See the `Validator` classes in `lib/schema` for their requirements.
