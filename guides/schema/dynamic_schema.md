---
layout: guide
doc_stub: false
search: true
section: Schema
title: Dynamic definition
desc: You can define your schema dynamically based on other data
---

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
