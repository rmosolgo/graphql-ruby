---
layout: doc_stub
search: true
title: Graphql::Generators::InstallGenerator
url: http://www.rubydoc.info/gems/graphql/Graphql/Generators/InstallGenerator
rubydoc_url: http://www.rubydoc.info/gems/graphql/Graphql/Generators/InstallGenerator
---

- Class: Graphql::Generators::InstallGenerator < Rails::Generators::Base
Add GraphQL to a Rails app with `rails g graphql:install`. 
Setup a folder structure for GraphQL: 
``` - app/
- graphql/
- resolvers/
- types/
- query_type.rb
- loaders/
- mutations/
- {app_name}_schema.rb
``` 
(Add `.gitkeep`s by default, support ` skip-keeps`) 
Add a controller for serving GraphQL queries: 
``` app/controllers/graphql_controller.rb ``` 
Add a route for that controller: 
```ruby # config/routes.rb post "/graphql", to: "graphql#execute"
``` 
Accept a ` relay` option which adds The root `node(id: ID!)` field.
Accept a ` batch` option which adds `GraphQL::Batch` setup. 
Use ` no-graphiql` to skip `graphiql-rails` installation. 
Instance methods:
create_dir, create_folder_structure, schema_name

