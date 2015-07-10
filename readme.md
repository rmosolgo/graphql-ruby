# graphql

[![Build Status](https://travis-ci.org/rmosolgo/graphql-ruby.svg?branch=master)](https://travis-ci.org/rmosolgo/graphql-ruby)
[![Gem Version](https://badge.fury.io/rb/graphql.svg)](https://rubygems.org/gems/graphql)
[![Code Climate](https://codeclimate.com/github/rmosolgo/graphql-ruby/badges/gpa.svg)](https://codeclimate.com/github/rmosolgo/graphql-ruby)
[![Test Coverage](https://codeclimate.com/github/rmosolgo/graphql-ruby/badges/coverage.svg)](https://codeclimate.com/github/rmosolgo/graphql-ruby)
[![built with love](https://cloud.githubusercontent.com/assets/2231765/6766607/d07992c6-cfc9-11e4-813f-d9240714dd50.png)](http://rmosolgo.github.io/react-badges/)

__Current status__: rewriting according to spec, see also the previous [prototype implementation](https://github.com/rmosolgo/graphql-ruby/tree/74ad3c30a6d8db010ec3856f5871f8a02fcfba42)!

## Overview

Build a schema:

```ruby

FacilityEnum = GraphQL::Enum.new("Facility", ["TENT", "RV", "CABIN", "BACKWOODS"])

CampsiteType = GraphQL::Type.new do
  name "Campsite"
  description "A place where you can set up camp"
  self.fields = {
    id:       field(type: !type.Int, desc: "The unique ID of this object"),
    facility: field(type: FacilityEnum, desc: "The setup of this campsite"),
  }
end

CampgroundType = GraphQL::Type.new do
  name "Campground"
  description "A collection of campsites which are administered together"
  self.fields = {
    id:         field(type: !type.Int, desc: "The unique ID of this object"),
    name:       field(type: !type.String, desc: "The advertised name of this campground"),
    campsites:  field(type: !type[CampsiteType], desc: "Campsites which compose this campground"),
  }
end

class FindField < GraphQL::Field
  attr_reader :type, :arguments
  def initialize(type:, model:)
    @type = type
    @model = model
    @arguments = {id: !type.Int}
  end

  def description
    "Find a #{@type.name} by id"
  end

  def resolve(target, arguments, context)
    @model.find(arguments["id"])
  end
end

QueryType = GraphQL::Type.new do
  name "Query"
  description "The root for queries of this system"
  self.fields = {
    campground:   FindField.new(type: CampgroundType, model: Campground),
    campsite:     FindField.new(type: CampsiteType,   model: Campsite),
    grandCanyon:  GraphQL::Field.new do |f|
      # you can define a field inline too
      f.name "Grand Canyon South Rim Campground"
      f.description "The campground on the south rim, maintained by the NPS"
      f.type CampgroundType
      f.resolve -> (obj, args, ctx) { Campground.find_by(name: "Grand Canyon")}
    },
end

Schema = GraphQL::Schema.new(query: QueryType, mutation: MutationType)
```

Execute a query:

```ruby
query_string = %|
  query getCampsite($campsiteId: Int!) {
    campsite(id: $campsiteId) {
      ... campsiteFields
    }
  }
  fragment campsiteFields on Campsite { id, facility }
|

query = GraphQL::Query.new(Schema, query_string, params: {"campsiteId" => 1})
query.result # =>
# {
#   "data" => {"campsite" => {"id" => 1, "facility" => "RV"}},
# }
```

## To Do:

- Express failure with `errors` key (http://facebook.github.io/graphql/#sec-Errors)
- Put response in `data` key
- Handle blank objects by returning `null`
- Directives
- Introspection: implement `SchemaType`, `DirectiveType`, introspect on Interface and Union
- Validations: implement lots of validators
- Serial vs non-serial execution?
- field merging (https://github.com/graphql/graphql-js/issues/19#issuecomment-118515077)

## Goals:

- Implement the GraphQL spec & support a Relay front end
- Provide idiomatic, plain-Ruby API with similarities to reference implementation where possible
- Support `graphql-rails`
