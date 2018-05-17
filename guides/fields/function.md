---
layout: guide
search: true
section: Fields
title: GraphQL::Function
desc: Create reusable resolve behavior with GraphQL::Function
index: 2
---


__Note__: See {% internal_link "Schema::Resolver", "/type_definitions/resolvers" %} for an improved version of `GraphQL::Function`.

_____

{{ "GraphQL::Function" | api_doc }} can hold generalized field logic which can be specialized on a field-by-field basis.

To define a function, make a class that extends {{ "GraphQL::Function" | api_doc }}:

```ruby
class FindRecord < GraphQL::Function
  attr_reader :type

  def initialize(model_class:, type:)
    @model_class = model_class
    @type = type
  end

  argument :id, !types.ID

  def call(obj, args, ctx)
    @model_class.find(args[:id])
  end
end
```

Then, connect the function to field definitions with the `function:` keyword:

```ruby
field :product, function: FindRecord.new(model_class: Product, type: Types::ProductType)
field :category, function: FindRecord.new(model_class: Category, type: Types::CategoryType)
```

Objects passed with the `function:` keyword must implement some field-related methods:

- `#arguments => Hash<String => GraphQL::Argument>`
- `#type => GraphQL::BaseType`
- `#call(obj, args, ctx) => Object`
- `#complexity => Integer, Proc`
- `#description => String, nil`
- `#deprecation_reason => String, nil`

`GraphQL::Function` provides some help in implementing these:

```ruby
class MyFunc < GraphQL::Function
  # Define a member of `#arguments`, just like the DSL:
  argument :id, types.ID

  # Define documentation:
  description "My Custom function"
  deprecation_reason "Just an example"

  type MyFuncReturnType
  # or, define one on the fly:
  type do
    name "MyFuncReturnType"
    # The returned object must implement these methods:
    field :name, types.String
    field :count, types.Int
  end
end
```

#### Function Inheritance

`GraphQL::Function`'s DSL-defined attributes are inherited, so you can subclass functions as much as you like!

```ruby
class FindRecord < GraphQL::Function
  # ...
end

# 👌 Arguments, description, etc are inherited as usual:
class BatchedFindRecord < FindRecord
  # ...
end
```

#### Extending Functions

Function attributes can be overridden by passing new values to the `field` helper. For example, to override the description:

```ruby
# Override the description:
field :post, description: "Find a Post by ID", function: FindRecord.new(model: Post) do
  # Add an argument:
  argument :authorId, types.ID
  # Provide custom configs:
  authorize :admin
end
```
