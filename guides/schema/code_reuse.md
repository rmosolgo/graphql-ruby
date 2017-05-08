---
layout: guide
title: Schema — Code Reuse
---

Here are a few techniques for code reuse with graphql-ruby:

- [Functions](#functions)
- [Dynamically defining types](#dynamically-defining-types)
- [Functional composition and `resolve`](#functional-composition--resolve)

Besides reducing duplicate code, these approaches also allow you to test parts of your schema in isolation.

## Functions

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
field :post, "Find a Post by ID", function: FindRecord.new(model: Post) do
  # Add an argument:
  argument :authorId, types.ID
  # Provide custom configs:
  authorize :admin
end
```

## Dynamically defining types

Many examples show how to use `.define` and store the result in a Ruby constant:

```ruby
PostType = GraphQL::ObjectType.define do ... end
```

However, you can call `.define` anytime and store the result anywhere. For example, you can define a method which creates types:

```ruby
# @return [GraphQL::ObjectType] a type derived from `model_class`
def create_type(model_class)
  GraphQL::ObjectType.define do
    name(model_class.name)
    description("Generated programmatically from model: #{model_class.name}")
    # Make a field for each column:
    model_class.columns.each do |column|
      field(column.name, convert_type(column.type))
    end
  end
end

# @return [GraphQL::BaseType] a GraphQL type for `database_type`
def convert_type(database_type)
  # ...
end
```

You can also define fields for associated objects. You'll need a way to access them programmatically.

```ruby
# Hash<Model => GraphQL::ObjectType>
MODEL_TO_TYPE = {}

def create_type(model_class)
  # ...
  GraphQL::ObjectType.define do
    # ...
    # Make a field for associations
    model_class.associations.each do |association|
      # The proc will be eval'd later - by that time, there will be a type in the lookup hash
      field(association.name, -> { MODEL_TO_TYPE[association.associated_model] })
    end
  end
end

all_models_in_application.each { |model_class| MODEL_TO_TYPE[model_class] = create_type(model_class) }
```

There is one caveat to using `.define`. The block is called with `instance_eval`, so `self` is a definition proxy, not the outer `self`. For this reason, you may need to assign values to local variables, then use them in `.define`. (`.define` has access to the local scope, but not the outer `self`.)

```ruby
class DynamicTypeDefinition
  attr_reader :model
  def initialize(model)
    @model = model
  end

  def to_graphql_type
    # This doesn't work because `model` is actually `self.model`, which doesn't work inside `.define`
    # GraphQL::ObjectType.define do
    #   name(model.name)
    # end
    #
    # Instead, assign a local variable first:
    model_name = model.name
    GraphQL::ObjectType.define do
      name(model_name)
    end
    # 👌
  end
end
```

## Functional composition & `resolve`

You can modify procs by wrapping them in other procs. This is a simple way to combine elements for a `resolve` function.

For example, you can wrap a proc with authorization logic:

```ruby
module Auth
  # Wrap resolve_proc in a check that `ctx[:current_user].can_read?(item_name)`
  #
  # @yield [obj, args, ctx] Field resolution parameters
  # @yieldreturn [Object] The return value for this field
  # @return [Proc] the passed-in block, modified to check for `can_read?(item_name)`
  def self.can_read(item_name, &block)
    ->(obj, args, ctx) do
      if ctx[:current_user].can_read?(item_name)
        # continue to the next call:
        block.call(obj, args, ctx)
      else
        nil
      end
    end
  end
end

# ...

QueryType = GraphQL::ObjectType.define do
  field :findPost, PostType do
    argument :id, !types.Int
    resolve(Auth.can_read(:post) do |obj, args, ctx|
      Post.find(args[:id])
    end)
  end
end
```

Now, the inner proc will only be called if the outer proc calls it.
