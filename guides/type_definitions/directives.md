# Directives

Directives are system-defined keywords with two kinds of uses:

- [runtime directives](#runtime-directives) _modify execution_, so that when they are present, the GraphQL runtime does something different;
- [schema directives](#schema-directives) _annotate schema definitions_, indicating different configurations or metadata about schemas and types.

## Runtime Directives

Runtime directives are server-defined keywords that modify GraphQL execution. All GraphQL systems have at least _two_ directives, `@skip` and `@include`. For example:

```ruby
query ProfileView($renderingDetailedProfile: Boolean!){
  viewer {
    handle
    # These fields will be included only if the check passes:
    ... @include(if: $renderingDetailedProfile) {
      location
      homepageUrl
    }
  }
}
```

Here's how the two built-in directives work:

- `@skip(if: ...)` skips the selection if the `if: ...` value is truthy ([GraphQL::Schema::Directive::Skip](rdoc-ref:GraphQL::Schema::Directive::Skip))
- `@include(if: ...)` includes the selection if the `if: ...` value is truthy ([GraphQL::Schema::Directive::Include](rdoc-ref:GraphQL::Schema::Directive::Include))

### Custom Runtime Directives

Custom directives extend [GraphQL::Schema::Directive](rdoc-ref:GraphQL::Schema::Directive):

```ruby
# app/graphql/directives/my_directive.rb
class Directives::MyDirective < GraphQL::Schema::Directive
  description "A nice runtime customization"
  location FIELD
end
```

Then, they're hooked up to the schema using `directive(...)`:

```ruby
class MySchema < GraphQL::Schema
  # Attach the custom directive to the schema
  directive(Directives::MyDirective)
end
```

And you can reference them in the query with `@myDirective(...)`:

```ruby
query {
  field @myDirective {
    id
  }
}
```

[GraphQL::Schema::Directive::Feature](rdoc-ref:GraphQL::Schema::Directive::Feature) and [GraphQL::Schema::Directive::Transform](rdoc-ref:GraphQL::Schema::Directive::Transform) are included in the library as examples.

### Runtime hooks

Directive classes may implement the following class methods to interact with the runtime:

- `def self.include?(obj, args, ctx)`: If this hook returns `false`, the nodes flagged by this directive will be skipped at runtime.
- `def self.resolve(obj, args, ctx)`: Wraps the resolution of flagged nodes. Resolution is passed as a __block__, so `yield` will continue resolution.

Looking for a runtime hook that isn't listed here? [open an issue](https://github.com/rmosolgo/graphql-ruby/issues/new?title=New+directive+hook%3A+%40something&body=%3C%21--+Describe+how+the+directive+would+be+used+and+then+how+you+might+implement+it+--%3E+) to start the conversation!

## Schema Directives

Schema directives are used in GraphQL's interface definition language (IDL). For example, `@deprecated` is built in to GraphQL-Ruby:

```ruby
type User {
  firstName @deprecated(reason: "Use `name` instead")
  lastName @deprecated(reason: "Use `name` instead")
  name
}
```

In the schema definition, directives express metadata about types, fields, and arguments.

### Custom Schema Directives

To make a custom schema directive, extend [GraphQL::Schema::Directive](rdoc-ref:GraphQL::Schema::Directive):

```ruby
# app/graphql/directives/permission.rb
class Directives::Permission < GraphQL::Schema::Directive
  argument :level, String
  locations FIELD_DEFINITION, OBJECT
end
```

Then, attach it to parts of your schema with `directive(...)`:

```ruby
class Types::JobPosting < Types::BaseObject
  directive Directives::Permission, level: "manager"
end
```

Arguments and fields also accept a `directives:` keyword:

```ruby
field :salary, Integer, null: false,
  directives: { Directives::Permission => { level: "manager" } }
```

After that:

- the configured object's `.directives` method will return an array containing an instance of the specified directive
- IDL dumps (from [Schema.to_definition](rdoc-ref:Schema.to_definition)) will include the configured directives

Similarly, [Schema.from_definition](rdoc-ref:Schema.from_definition) parses directives from IDL strings.

For a couple of built-in examples, check out:

- [GraphQL::Schema::Directive::Deprecated](rdoc-ref:GraphQL::Schema::Directive::Deprecated) which implements `deprecation_reason` (via [GraphQL::Schema::Member::HasDeprecationReason](rdoc-ref:GraphQL::Schema::Member::HasDeprecationReason))
- [GraphQL::Schema::Directive::Flagged](rdoc-ref:GraphQL::Schema::Directive::Flagged), which is an example of using schema directives to implement [visibility](/authorization/visibility)

## Custom Name

By default, the directive's name is taken from the class name. You can override this with `graphql_name`, for example:

```ruby
class Directives::IsPrivate < GraphQL::Schema::Directive
  graphql_name "someOtherName"
end
```

## Arguments

Like fields, directives may have [arguments](/fields/arguments) :

```ruby
argument :if, Boolean,
  description: "Skips the selection if this condition is true"
```
