---
layout: guide
doc_stub: false
search: true
section: Type Definitions
title: Input Objects
desc: Input objects are sets of key-value pairs which can be used as field arguments.
index: 3
---

Input object types are complex inputs for GraphQL operations. They're great for fields that need a lot of structured input, like mutations or search fields. In a GraphQL request, it might look like this:

```ruby
mutation {
  createPost(attributes: { title: "Hello World", fullText: "This is my first post", categories: [GENERAL] }) {
    #                    ^ Here is the input object ..................................................... ^
  }
}
```

Like a Ruby `Hash`, an input object consists of keys and values. Unlike a Hash, its keys and value types must be defined statically, as part of the GraphQL system. For example, here's an input object, expressed in the [GraphQL Schema Definition Language](https://graphql.org/learn/schema/#type-language) (SDL):

```ruby
input PostAttributes {
  title: String!
  fullText: String!
  categories: [PostCategory!]
}
```

This input object has three possible keys:

- `title` is required (denoted by `!`), and must be a `String`
- `fullText` is also a required String
- `categories` is optional (it doesn't have `!`), and if present, it must be a list of `PostCategory` values.

## Defining Input Object Types

Input object types extend {{ "GraphQL::Schema::InputObject" | api_doc }} and define key-value pairs with the `argument(...)` method. For example:

```ruby
# app/graphql/types/base_input_object.rb
# Add a base class
class Types::BaseInputObject < GraphQL::Schema::InputObject
end

class Types::PostAttributes < Types::BaseInputObject
  description "Attributes for creating or updating a blog post"
  argument :title, String, "Header for the post"
  argument :full_text, String, "Full body of the post"
  argument :categories, [Types::PostCategory], required: false
end
```

For a full description of the `argument(...)` method, see the {% internal_link "argument section of the Objects guide","/type_definitions/objects#field-arguments" %}.

## Using Input Objects

Input objects are passed to field methods as an instance of their definition class. So, inside the field method, you can access any key of the object by:

- calling its method, corresponding to the name (underscore-cased)
- calling `#[]` with the _camel-cased_ name of the argument (this is for compatibility with previous GraphQL-Ruby versions)

```ruby
# This field takes an argument called `attributes`
# which will be an instance of `PostAttributes`
field :create_post, Types::Post, null: false do
  argument :attributes, Types::PostAttributes
end

def create_post(attributes:)
  puts attributes.class.name
  # => "Types::PostAttributes"
  # Access a value by method (underscore-cased):
  puts attributes.full_text
  # => "This is my first post"
  # Or by hash-style lookup (camel-cased, for compatibility):
  puts attributes[:fullText]
  # => "This is my first post"
end
```

## Customizing Input Objects

You can customize the `GraphQL::Schema::Argument` class which is used for input objects:

```ruby
class Types::BaseArgument < GraphQL::Schema::Argument
  # your customization here ...
end


class Types::BaseInputObject < GraphQL::Schema::InputObject
  # Hook up the customized argument class
  argument_class(Types::BaseArgument)
end
```


You can also add or override methods on input object classes to customize them.  They have two instance variables by default:

- `@arguments`: A {{ "GraphQL::Query::Arguments" | api_doc }} instance
- `@context`: The current {{ "GraphQL::Query::Context" | api_doc }}

Any extra methods you define on the class can be used for field resolution, as demonstrated above.

## Converting to Other Ruby Objects

Your input objects can be automatically converted to other Ruby types before they're passed to your application code. This is an easy way to use `Range`'s in your schema:

```ruby
class Types::DateRangeInput < Types::BaseInputObject
  description "Range of dates"
  argument :min, Types::Date, "Minimum value of the range"
  argument :max, Types::Date, "Maximum value of the range"

  def prepare
    min..max
  end
end

class Types::CalendarType < Types::BaseObject
  field :appointments, [Types::Appointment], "Appointments on your calendar", null: false do
    argument :during, Types::DateRangeInput, "Only show appointments within this range"
  end

  def appointments(during:)
    # during will be an instance of Range
    object.appointments.select { |appointment| during.cover?(appointment.date) }
  end
end
```
