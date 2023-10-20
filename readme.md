# graphql <img src="https://cloud.githubusercontent.com/assets/2231765/9094460/cb43861e-3b66-11e5-9fbf-71066ff3ab13.png" height="40" alt="graphql-ruby"/>

[![CI Suite](https://github.com/rmosolgo/graphql-ruby/actions/workflows/ci.yaml/badge.svg)](https://github.com/rmosolgo/graphql-ruby/actions/workflows/ci.yaml)
[![Gem Version](https://badge.fury.io/rb/graphql.svg)](https://rubygems.org/gems/graphql)

A Ruby implementation of [GraphQL](https://graphql.org/).

- [Website](https://graphql-ruby.org/)
- [API Documentation](https://www.rubydoc.info/github/rmosolgo/graphql-ruby)
- [Newsletter](https://tinyletter.com/graphql-ruby)

## Installation

Install from RubyGems by adding it to your `Gemfile`, then bundling.

```ruby
# Gemfile
gem 'graphql'
```

```
$ bundle install
```

## Getting Started

```
$ rails generate graphql:install
```

After this, you may need to run `bundle install` again, as by default graphiql-rails is added on installation.

Or, see ["Getting Started"](https://graphql-ruby.org/getting_started.html).

## Upgrade

I also sell [GraphQL::Pro](https://graphql.pro) which provides several features on top of the GraphQL runtime, including [Pundit authorization](https://graphql-ruby.org/authorization/pundit_integration), [CanCan authorization](https://graphql-ruby.org/authorization/can_can_integration), [Pusher-based subscriptions](https://graphql-ruby.org/subscriptions/pusher_implementation) and [persisted queries](https://graphql-ruby.org/operation_store/overview). Besides that, Pro customers get email support and an opportunity to support graphql-ruby's development!

## Goals

- Implement the GraphQL spec & support a Relay front end
- Provide idiomatic, plain-Ruby API with similarities to reference implementation where possible
- Support Ruby on Rails and Relay

## Getting Involved

- __Say hi & ask questions__ in the #graphql-ruby channel on [Discord](https://discord.com/invite/xud7bH9).
- __Report bugs__ by posting a description, full stack trace, and all relevant code in a  [GitHub issue](https://github.com/rmosolgo/graphql-ruby/issues).
- __Start hacking__ with the [Development guide](https://graphql-ruby.org/development).
