# graphql

[![Build Status](https://travis-ci.org/rmosolgo/graphql-ruby.svg?branch=master)](https://travis-ci.org/rmosolgo/graphql-ruby)
[![Gem Version](https://badge.fury.io/rb/graphql.svg)](https://rubygems.org/gems/graphql)
[![Dependency Status](https://gemnasium.com/rmosolgo/graphql-ruby.svg)](https://gemnasium.com/rmosolgo/graphql-ruby)
[![Code Climate](https://codeclimate.com/github/rmosolgo/graphql-ruby/badges/gpa.svg)](https://codeclimate.com/github/rmosolgo/graphql-ruby)
[![Test Coverage](https://codeclimate.com/github/rmosolgo/graphql-ruby/badges/coverage.svg)](https://codeclimate.com/github/rmosolgo/graphql-ruby)
[![built with love](https://cloud.githubusercontent.com/assets/2231765/6766607/d07992c6-cfc9-11e4-813f-d9240714dd50.png)](http://rmosolgo.github.io/react-badges/)


Create a GraphQL interface by implementing [__nodes__](#nodes) and [__calls__](#calls), then running [__queries__](#queries).

API Docs: <http://rubydoc.info/gems/graphql>

## To do:

- add testing examples
- add owner info for debugging
- How do you express failure? HTTP response? `errors` key?
- Handle blank objects in nested calls (how? wait for spec)
- Implement calls as arguments
- double-check how to handle `pals.first(3) { count }`
- Implement call argument introspection (wait for spec)

## Example Implementation

- See test implementation in [`/spec/support/dummy_app/nodes.rb`](https://github.com/rmosolgo/graphql/blob/master/spec/support/nodes.rb)
- See `graphql-ruby-demo` with Rails on [github](https://github.com/rmosolgo/graphql-ruby-demo) or [heroku](http://graphql-ruby-demo.herokuapp.com/)

<a href="http://graphql-ruby-demo.herokuapp.com/" target="_blank"><img src="https://cloud.githubusercontent.com/assets/2231765/6839956/c62c1fca-d32d-11e4-9e54-ec6743d3e4b5.png" style="max-width: 800px;"/></a>


## Usage

- Implement _nodes_ that wrap objects in your application
- Implement _calls_ that return those objects (and may mutate the application state)
- Execute _queries_ and return the result.

### Nodes

Nodes are delegators that wrap objects in your app. You must whitelist fields by declaring them in the class definition.


```ruby
class FishNode < GraphQL::Node
  exposes "Fish"
  cursor(:id)
  field.number(:id)
  field.string(:name)
  field.string(:species)
  # specify an `AquariumNode`:
  field.aquarium(:aquarium)
end
```

You can also declare connections between objects:

```ruby
class AquariumNode < GraphQL::Node
  exposes "Aquarium"
  cursor(:id)
  field.number(:id)
  field.number(:occupancy)
  field.connection(:fishes)
end
```

You can make custom connections:

```ruby
class FishSchoolConnection < GraphQL::Connection
  type :fish_school # now it is a field type
  call :largest, -> (prev_value, number)  { fishes.sort_by(&:weight).first(number.to_i) }

  field.number(:count) # delegated to `target`
  field.boolean(:has_more)

  def has_more
    # the `largest()` call may have removed some items:
    target.count < original_target.count
  end
end
```

Then use them:

```ruby
class AquariumNode < GraphQL::Node
  field.fish_school(:fishes)
end
```

And in queries:

```
aquarium(1) {
  name,
  occupancy,
  fishes.largest(3) {
      edges {
        node { name, species }
      },
      count,
      has_more
    }
  }
}
```

### Calls

Calls selectively expose your application to the world. They always return values and they may perform mutations.

Calls declare returns, declare arguments, and implement `#execute!`.

This call just finds values:

```ruby
class FindFishCall < GraphQL::RootCall
  returns :fish
  argument.number(:id)
  def execute!(id)
    Fish.find(id)
  end
end
```

This call performs a mutation:

```ruby
class RelocateFishCall < GraphQL::RootCall
  returns :fish, :previous_aquarium, :new_aquarium
  argument.number(:fish_id)
  argument.number(:new_aquarium_id)

  def execute!(fish_id, new_aquarium_id)
    fish = Fish.find(fish_id)

    # context is defined by the query, see below
    if !context[:user].can_move?(fish)
      raise RelocateNotAllowedError
    end

    previous_aquarium = fish.aquarium
    new_aquarium = Aquarium.find(new_aquarium_id)
    fish.update_attributes(aquarium: new_aquarium)
    {
      fish: fish,
      previous_aquarium: previous_aquarium,
      new_aquarium: new_aquarium,
    }
  end
end
```

### Queries

When your system is setup, you can perform queries from a string.

```ruby
query_str = "find_fish(1) { name, species } "
query     = GraphQL::Query.new(query_str)
result    = query.as_result

result
# {
#   "1" => {
#     "name" => "Sharky",
#     "species" => "Goldfish",
#   }
# }
```

Each query may also define a `context` object which will be accessible at every point in execution.

```ruby
query_str = "move_fish(1, 3) { fish { name }, new_aquarium { occupancy } }"
query_ctx = {user: current_user, request: request}
query     = GraphQL::Query.new(query_str, context: query_ctx)
result    = query.as_result

result
# {
#   "fish" => {
#     "name" => "Sharky"
#   },
#   "new_aquarium" => {
#     "occupancy" => 12
#   }
# }
```

You could do something like this [inside a Rails controller](https://github.com/rmosolgo/graphql-ruby-demo/blob/master/app/controllers/queries_controller.rb#L5).
