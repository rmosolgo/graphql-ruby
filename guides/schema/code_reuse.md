---
layout: guide
search: true
title: Schema — Code Reuse
---

Here are a few techniques for code reuse with graphql-ruby:

- [Dynamically defining types](#dynamically-defining-types)
- [Functional composition and `resolve`](#functional-composition--resolve)

Besides reducing duplicate code, these approaches also allow you to test parts of your schema in isolation.

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
