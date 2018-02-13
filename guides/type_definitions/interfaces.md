---
layout: guide
search: true
section: Type Definitions
title: Interfaces
desc: Interfaces are lists of fields which objects may implement
index: 4
experimental: true
---

An interface has fields, but it's never actually instantiated. Instead, objects may _implement_ interfaces, which makes them a _member_ of that interface. Also, fields may _return_ interface types. When this happens, the returned object may be any member of that interface.

For example, let's say a `Customer` may be either an `Individual` or a `Company`. Here's the structure in the GraphQL Schema Definition Language (SDL):

```ruby
interface Customer {
  name: String!
  outstandingBalance: Int!
}

type Company implements Customer {
  employees: [Individual!]!
  name: String!
  outstandingBalance: Int!
}

type Individual implements Customer {
  company: Company
  name: String!
  outstandingBalance: Int!
}
```

Notice that the `Customer` interface requires two fields, `name: String!` and `outstandingBalance: Int!`. Both `Company` and `Individual` implement those fields, so they can implement `Customer`. Their implementation of `Customer` is made explicit by `implements Customer` in their definition.

When querying, you can get the fields on an interface:

```ruby
customers(first: 5) {
  name
  outstandingBalance
}
```

Whether the objects are `Company` or `Individual`, it doesn't matter -- you still get their `name` and `outstandingBalance`. If you want some object-specific fields, you can query them with an _inline fragment_, for example:

```ruby
customers(first: 5) {
  name
  ... on Individual {
    company { name }
  }
}
```

This means, "if the customer is an `Individual`, also get the customer's company name".

Interfaces are a good choice whenever a set of objects are used interchangeably, and they share several significant fields in common. When they don't have fields in common, use a {% internal_link "Union", "/type_definitions/unions.md" %} instead.

## Defining Interface Types

Interfaces extend {{ "GraphQL::Schema::Interface" | api_doc }}. First, make a base class:

```ruby
class Types::BaseInterface < GraphQL::Schema::Interface
end
```

Then, extend that for each interface:

```ruby
class Types::RetailItem < Types::BaseInterface
  description "Something that can be bought"
  field :price, Types::Price, "How much this item costs", null: false

  # Optional: if this method is defined, it overrides `Schema.resolve_type`
  def self.resolve_type(object, context)
    # ...
  end

  module Implementation
    # optional, see below
  end
end
```

Interface classes are never instantiated. At runtime, only their `.resolve_type` methods are called (if they're defined).

### Resolve Type

When a field's return type is an interface, GraphQL has to figure out what _specific_ object type to use for the return value. In the example above, each `customer` must be categorized as an `Individual` or `Company`. You can do this by:

- Providing a top-level `Schema.resolve_type` method; _OR_
- Providing an interface-level `.resolve_type` method.

This method will be called whenever an object must be disambiguated. For example:

```ruby
class Types::RetailItem < Types::BaseInterface
  # Determine what object type to use for `object`
  def self.resolve_type(object, context)
    if object.is_a?(::Car) || object.is_a?(::Truck)
      Types::Car
    elsif object.is_a?(::Purse)
      Types::Purse
    else
      raise "Unexpected RetailItem: #{object.inspect}"
    end
  end
end
```

### Implementation modules

An interface may contain a module named `Implementation`. If it does, that module will be included into any `Object` class which implements the interface. For example, this `Implementation` module contains the `#price` method:

```ruby
class Types::RetailItem < Types::BaseInterface
  field :price, Types::Price, null: false

  module Implementation
    def price
      Price.new(price_in_cents)
    end
  end
end
```

When the interface is implemented by an `Object`:

```ruby
class Types::Car < Types::BaseObject
  implements Types::RetailItem
end
```

Then the object gets a few things from the interface:

- Any `field` definitions from the interface (which may be overridden by the `Object`)
- The `Implementation` module is `include`-d into the object, so it gets any methods from that module (which may be overridden by the `Object`)

Specifically, in the example above, `CarType` would get a field named `price` and a `#price` method which implements that field.
