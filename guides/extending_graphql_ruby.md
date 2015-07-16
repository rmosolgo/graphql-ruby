# Extending `graphql-ruby`

`graphql-ruby` ships with many loosely-coupled components which may be swapped out for custom ones. At create-time, `GraphQL::Schema` validates itself to ensure all parts are compliant.

## Custom Types

`graphql-ruby` ships with some types (`GraphQL::ObjectType`, `GraphQL::Union`, `GraphQL::Interface`), but you can ignore these entirely and write your own, if you want.  Any object can perform the role of a type (whether object, union, interface, etc) as long as it implements the necessary behavior.


- All types should implement:
  - `.name`, returning a string
  - `.description`, returning a string
  - `.kind`, returning the correct item from `GraphQL::TypeKinds` (eg, `GraphQL::TypeKinds::UNION`)
- In addition:
  - Objects should implement:
    - `.interfaces`, returning an array of interfaces
  - Objects and interfaces should implement:
    - `.fields`, returning a hash of `String => Field` pairs
  - Unions and interfaces should implement:
    - `.possible_types`, returning objects
    - `.resolve_type(value)`, which returns an object type for `value`
  - Enums should implement:
    - `.values`, returning a hash of `String => EnumValue` pairs
    - `EnumValue` needs `.name`, `.description` and `.deprecation_reason`
  - Input objects should implement:
    - `.input_values`, returning a hash of `String => InputValue` pairs
    - `InputValue` needs `.name`, `.description`, `.type` and `.default_value`

For example, this class could generate object types:

```ruby
module CustomObjectType
  module_function

  def name
    "CustomObject"
  end

  def description
    "A custom type for graphql-ruby"
  end

  def kind
    # This one has to be from graphql-ruby:
    GraphQL::TypeKinds::OBJECT
  end

  def fields
    {
      "someValue" => GraphQL::Field.new { |f| ... }
    }
  end

  def interfaces
    []
  end
end

# It implements the required behaviors:
CustomObjectType.name         # CustomObject
CustomObjectType.description  # A custom type for graphql-ruby
CustomObjectType.kind         # GraphQL::TypeKinds::OBJECT
CustomObjectType.fields       # { "someValue" => ... }
CustomObjectType.interfaces   # []
```

Since `CustomObjectType` implements all the required methods, you could use it a `GraphQL::Schema`, just like an object derived from `GraphQL::ObjectType`. You can use this flexibility to design your own type generators.

## Custom Fields

In a similar way, you can use any object as a field. To be used as a field, an object must implement:

- `.name`, string
- `.description`, string
- `.deprecation_reason`, string
- `.type`, returning a valid type object (described above)
- `.arguments`, returning a hash of `String => InputValue` pairs
- `.resolve(object, arguments, context)`, returns any object to be wrapped by `type` (executed by `GraphQL::Query`)


You can see a custom field, `FetchField`, in the [dummy app](https://github.com/rmosolgo/graphql-ruby/blob/master/spec/support/dummy_app.rb).
