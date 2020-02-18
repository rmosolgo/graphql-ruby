---
layout: guide
doc_stub: false
search: true
section: GraphQL Pro - OperationStore
title: Getting Started
desc: Add GraphQL::Pro::OperationStore to your app
index: 1
pro: true
---

To use `GraphQL::Pro::OperationStore` with your app, follow these steps:

- [Check the dependencies](#dependencies) to make sure `OperationStore` is supported
- [Prepare the database](#prepare-the-database) for `OperationStore`'s  data
- [Add `OperationStore`](#add-operationstore) to your GraphQL schema
- [Add routes](#add-routes) for the Dashboard and sync API
- [Update your controller](#update-the-controller) to support persisted queries
- {% internal_link "Add a client","/operation_store/client_workflow" %} to start syncing queries

#### Dependencies

`OperationStore` requires two gems in your application environment:

- {% internal_link "ActiveRecord", "/operation_store/active_record_backend" %} or {% internal_link "Redis", "/operation_store/redis_backend" %} for persistence. (Using another ORM or backend? Please {% open_an_issue "Backend support request for OperationStore" %} to request support!)
- `Rack`: to serve the Dashboard and Sync API. (In Rails, this is provided by `config/routes.rb`.)

These are bundled with Rails by default.

#### Prepare the Database

If you're going to store data with ActiveRecord, {% internal_link "migrate the database", "/operation_store/active_record_backend" %} to prepare tables for it.

#### Add `OperationStore`

To hook up the storage to your schema, add the plugin:

```ruby
class MySchema < GraphQL::Schema
  # ...
  use GraphQL::Pro::OperationStore
end
```

By default, it uses `ActiveRecord`. It also accepts:

- `redis:`, for using a {% internal_link "Redis backend", "/operation_store/redis_backend" %}; OR
- `backend_class:`, for implementing custom persistence.

#### Add Routes

To use `OperationStore`, add two routes to your app:

```ruby
# config/routes.rb

# Include GraphQL::Pro's routing extensions:
using GraphQL::Pro::Routes

Rails.application.routes.draw do
  # ...
  # Add the Dashboard
  # TODO: authorize, see the dashboard guide
  mount MySchema.dashboard, at: "/graphql/dashboard"
  # Add the Sync API (authorization built-in)
  mount MySchema.operation_store_sync, at: "/graphql/sync"
end
```

`MySchema.operation_store_sync` receives pushes from clients. See {% internal_link "Client Workflow","/operation_store/client_workflow" %} for more info on how this endpoint is used.

`MySchema.dashboard` includes a web view to the `OperationStore`, visible at `/graphql/dashboard`. See the {% internal_link "Dashboard guide", "/pro/dashboard" %} for more details, including authorization.

{{ "/operation_store/graphql_ui.png" | link_to_img:"GraphQL Persisted Operations Dashboard" }}

The are both Rack apps, so you can mount them in Sinatra or any other Rack app.

#### Update the Controller

Add `operation_id:` to your GraphQL context:

```ruby
# app/controllers/graphql_controller.rb
context = {
  # Relay / Apollo 1.x:
  operation_id: params[:operationId]
  # Or, Apollo Link:
  # operation_id: params[:extensions][:operationId]
}

MySchema.execute(
  # ...
  context: context,
)
```

`OperationStore` will use `operation_id` to fetch the operation from the database.

See {% internal_link "Server Management","/operation_store/server_management" %} for details about rejecting GraphQL from `params[:query]`.

#### Next Steps

Sync your operations with the {% internal_link "Client Workflow","/operation_store/client_workflow" %}.
