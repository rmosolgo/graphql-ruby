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

- `ActiveRecord` to access tables in your database. (Using another ORM or backend? Please {% open_an_issue "Backend support request for OperationStore" %} to request support!)
- `Rack`: to serve the Dashboard and Sync API. (In Rails, this is provided by `config/routes.md`.)

These are bundled with Rails by default.

#### Prepare the Database

`GraphQL::Pro::OperationStore` requires some database tables. You can add these with a migration:

```bash
$ rails generate migration SetupOperationStore
```

Then open the migration file and add:

```ruby
# ...
# implement the change method with:
def change
  create_table :graphql_clients do |t|
    t.column :name, :string, null: false
    t.column :secret, :string, null: false
    t.timestamps
  end
  add_index :graphql_clients, :name, unique: true
  add_index :graphql_clients, :secret, unique: true

  create_table :graphql_client_operations do |t|
    t.references :graphql_client, null: false
    t.references :graphql_operation, null: false
    t.column :alias, :string, null: false
    t.timestamps
  end
  add_index :graphql_client_operations, [:graphql_client_id, :alias], unique: true, name: "graphql_client_operations_pairs"

  create_table :graphql_operations do |t|
    t.column :digest, :string, null: false
    t.column :body, :text, null: false
    t.column :name, :string, null: false
    t.timestamps
  end
  add_index :graphql_operations, :digest, unique: true

  create_table :graphql_index_entries do |t|
    t.column :name, :string, null: false
  end
  add_index :graphql_index_entries, :name, unique: true

  create_table :graphql_index_references do |t|
    t.references :graphql_index_entry, null: false
    t.references :graphql_operation, null: false
  end
  add_index :graphql_index_references, [:graphql_index_entry_id, :graphql_operation_id], unique: true, name: "graphql_index_reference_pairs"
end
```

#### Add `OperationStore`

To hook up the storage to your schema, add the plugin:

```ruby
class MySchema < GraphQL::Schema
  # ...
  use GraphQL::Pro::OperationStore
end
```

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
