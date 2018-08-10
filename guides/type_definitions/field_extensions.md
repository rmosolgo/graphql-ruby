---
layout: guide
doc_stub: false
search: true
section: Type Definitions
title: Field Extensions
desc: Programmatically modify field configuration and resolution
index: 10
class_based_api: true
---

{{ "GraphQL::Schema::FieldExtension" | api_doc }} provides a way to modify user-defined fields in a programmatic way. For example, Relay connections may are implemented as a field extension.

### Making a new extension

Field extensions are subclasses of {{ "GraphQL::Schema::FieldExtension" | api_doc }}:

```ruby
class MyExtension < GraphQL::Schema::FieldExtension
end
```

### Using an extension

Defined extensions can be added to fields using the `extensions: [...]` option or the `extension(...)` method:

```ruby
field :name, String, null: false, extensions: [UpcaseExtension]
# or:
field :description, String, null: false do
  extension(UpcaseExtension)
end
```

See below for how extensions may modify fields.

### Modifying field configuration

When extensions are attached, they are initialized with a `field:` and `options:`. During `#initialize`, they may extend the field they're attached to. For example:

```ruby
class SearchableExtension < GraphQL::Schema::FieldExtension
  def initialize(field:, options:)
    # add an argument to this field:
    field.argument(:query, String, required: false, description: "A search query")
    # and always call super:
    super
  end
end
```

This way, an extension can encapsulate a behavior requiring several configuration options.

### Modifying field execution

Extensions have two hooks that wrap field resolution. Since GraphQL-Ruby supports deferred execution, these hooks _might not_ be called back-to-back.

First, {{ "GraphQL::Schema::FieldExtension#before_resolve" | api_doc }} is called. `before_resolve` should `yield(object, arguments)` to continue execution. If it doesn't `yield`, then the field won't resolve, and the methods return value will be returned to GraphQL instead.

After resolution, {{ "GraphQL::Schema::FieldExtension#after_resolve" | api_doc }} is called. Whatever that method returns will be used as the field's return value.

See the linked API docs for the parameters of those methods.

#### Execution "memo"

One parameter to `after_resolve` deserves special attention: `memo:`. `before_resolve` _may_ yield a third value. For example:

```ruby
def before_resolve(object:, arguments:, **rest)
  # yield the current time as `memo`
  yield(object, arguments, Time.now.to_i)
end
```

If a third value is yielded, it will be passed to `after_resolve` as `memo:`, for example:

```ruby
def after_resolve(value:, memo:, **rest)
  puts "Elapsed: #{Time.now.to_i - memo}"
  # Return the original value
  value
end
```

This allows the `before_resolve` hook to pass data to `after_resolve`.

Instance variables may not be used because, in a given GraphQL query, the same field may be resolved several times concurrently, and that would result in overriding the instance variable in an unpredictable way. (In fact, extensions are frozen to prevent instance variable writes.)

### Extension options

The `extension(...)` method takes an optional second argument, for example:

```ruby
extension(LimitExtension, limit: 20)
```

In this case, `{limit: 20}` will be passed as `options:` to `#initialize` and `options[:limit]` will be `20`.

For example, options can be used for modifying execution:

```ruby
def after_resolve(value:, **rest)
  # Apply the limit from the options
  value.limit(options[:limit])
end
```
