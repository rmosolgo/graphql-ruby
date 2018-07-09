---
layout: guide
doc_stub: false
search: true
title: Generators
section: Schema
desc: Use Rails generators to install GraphQL and scaffold new types.
index: 3
---

If you're using GraphQL with Ruby on Rails, you can use generators to:

- [setup GraphQL](#graphqlinstall), including [GraphiQL](https://github.com/graphql/graphiql), [GraphQL::Batch](https://github.com/Shopify/graphql-batch), and [Relay](https://facebook.github.io/relay/)
- [scaffold types](#scaffolding-types)
- [scaffold Relay mutations](#scaffolding-mutations)
- [scaffold GraphQL::Batch loaders](#scaffolding-loaders)

## graphql:install

You can add GraphQL to a Rails app with `graphql:install`:

```
rails generate graphql:install
```

This will:

- Set up a folder structure in `app/graphql/`
- Add schema definition
- Add base type classes
- Add a `Query` type definition
- Add a route and controller for executing queries
- Install [`graphiql-rails`](https://github.com/rmosolgo/graphiql-rails)

After installing you can see your new schema by:

- `bundle install`
- `rails server`
- Open `localhost:3000/graphiql`

### Options

- `--relay` will add [Relay](https://facebook.github.io/relay/)-specific code to your schema
- `--batch` will add [GraphQL::Batch](https://github.com/Shopify/graphql-batch) to your gemfile and include the setup in your schema
- `--no-graphiql` will exclude `graphiql-rails` from the setup
- `--schema=MySchemaName` will be used for naming the schema (default is `#{app_name}Schema`)

## Scaffolding Types

Several generators will add GraphQL types to your project. Run them with `-h` to see the options:

- `rails g graphql:object`
- `rails g graphql:interface`
- `rails g graphql:union`
- `rails g graphql:enum`


## Scaffolding Mutations

You can prepare a Relay Classic mutation with

```
rails g graphql:mutation #{mutation_name}
```

## Scaffolding Loaders

You can prepare a GraphQL::Batch loader with

```
rails g graphql:loader
```
