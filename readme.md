# graphql <img src="https://cloud.githubusercontent.com/assets/2231765/9094460/cb43861e-3b66-11e5-9fbf-71066ff3ab13.png" height="40" alt="graphql-ruby"/>

[![Build Status](https://travis-ci.org/rmosolgo/graphql-ruby.svg?branch=master)](https://travis-ci.org/rmosolgo/graphql-ruby)
[![Gem Version](https://badge.fury.io/rb/graphql.svg)](https://rubygems.org/gems/graphql)
[![Code Climate](https://codeclimate.com/github/rmosolgo/graphql-ruby/badges/gpa.svg)](https://codeclimate.com/github/rmosolgo/graphql-ruby)
[![Test Coverage](https://codeclimate.com/github/rmosolgo/graphql-ruby/badges/coverage.svg)](https://codeclimate.com/github/rmosolgo/graphql-ruby)
[![built with love](https://cloud.githubusercontent.com/assets/2231765/6766607/d07992c6-cfc9-11e4-813f-d9240714dd50.png)](http://rmosolgo.github.io/react-badges/)

A Ruby implementation of [GraphQL](http://graphql.org/).

- [Website](https://rmosolgo.github.io/graphql-ruby)
- [API Documentation](http://www.rubydoc.info/github/rmosolgo/graphql-ruby)
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

Or, see ["Getting Started"](https://rmosolgo.github.io/graphql-ruby/).

## Upgrade

I also sell [GraphQL::Pro](http://graphql.pro) which provides several features on top of the GraphQL runtime, including [authorization](http://rmosolgo.github.io/graphql-ruby/pro/authorization), [monitoring](http://rmosolgo.github.io/graphql-ruby/pro/monitoring) plugins and [static queries](http://rmosolgo.github.io/graphql-ruby/pro/persisted_queries). Besides that, Pro customers get email support and an opportunity to support graphql-ruby's development!

## Goals

- Implement the GraphQL spec & support a Relay front end
- Provide idiomatic, plain-Ruby API with similarities to reference implementation where possible
- Support Ruby on Rails and Relay

## Getting Involved

- __Say hi & ask questions__ in the [#ruby channel on Slack](http://bit.ly/rubyslack) or [on Twitter](https://twitter.com/rmosolgo)!
- __Report bugs__ by posting a description, full stack trace, and all relevant code in a  [GitHub issue](https://github.com/rmosolgo/graphql-ruby/issues).
- __Features & patches__ are welcome! Consider discussing it in an [issue](https://github.com/rmosolgo/graphql-ruby/issues) or in the [#ruby channel on Slack](http://bit.ly/rubyslack) to make sure we're on the same page.
- __Run the tests__ with `rake test` or start up guard with `bundle exec guard`.
- __Build the site__ with `rake site:serve`, then visit `http://localhost:4000/graphql-ruby/`.
