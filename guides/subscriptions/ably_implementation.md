---
layout: guide
doc_stub: false
search: true
section: Subscriptions
title: Ably Implementation
desc: GraphQL subscriptions over Ably
index: 7
pro: true
---

[GraphQL Pro](https://graphql.pro) includes a subscription system based on [Redis](https://redis.io) and [Ably](https://ably.io) which works with any Ruby web framework.

After creating an app on Ably, you can hook it up to your GraphQL schema.

- [How it Works](#how-it-works)
- [Database setup](#database-setup)
- [Schema configuration](#schema-configuration)
- [Execution configuration](#execution-configuration)
- [Webhook configuration](#webhook-configuration)
- [Authorization](#authorization)
- [Serializing context](#serializing-context)
- [Dashboard](#dashboard)
- [Development tips](#development-tips)
- [Client configuration](#client-configuration)

## How it Works

This subscription implementation uses a hybrid approach:

- __Your app__ takes GraphQL queries an runs them
- __Redis__ stores subscription data for later updates
- __Ably__ sends updates to subscribed clients

So, the lifecycle goes like this:

- A `subscription` query is sent by HTTP Post to your server (just like a `query` or `mutation`)
- The response contains a Ably channel ID (as an HTTP header) which the client may subscribe to
- The client opens that Ably channel
- When the server triggers updates, they're delivered over the Ably channel
- When the client unsubscribes, the server receives a webhook and responds by removing its subscription data

Here's another look:

```
1. Subscription is created in your app

          HTTP POST
        .---------->   write to Redis
      📱            ⚙️ -----> 💾
        <---------'
        X-Subscription-ID: 1234


2. Client opens a connection to Ably

          websocket
      📱 <---------> ☁️


3. The app sends updates via Ably

      ⚙️ ---------> ☁️ ------> 📱
        POST           update
      (via gem)   (via websocket)


4. When the client unsubscribes, Ably notifies the app

          webhook
      ⚙️ <-------- ☁️  (disconnect) 📱
```


By using this configuration, you can use GraphQL subscriptions without hosting a push server yourself!

## Ably setup
Add `ably-rest` to your `Gemfile`:

```ruby
gem 'ably-rest'
```

and `bundle install`.

## Database setup

Subscriptions require a _persistent_ Redis database, configured with:

```sh
maxmemory-policy noeviction
# optional, more durable persistence:
appendonly yes
```

Otherwise, Redis will drop data that doesn't fit in memory (read more in ["Redis persistence"](https://redis.io/topics/persistence)).

If you're already using Redis in your application, see ["Storing Data in Redis"](https://www.mikeperham.com/2015/09/24/storing-data-with-redis/) for options to isolate data and tune your configuration.

## Schema configuration

Add `redis` to your `Gemfile`:

```ruby
gem 'redis'
```

and `bundle install`. Then create a Redis instance:

```ruby
# for example, in an initializer:
$graphql_subscriptions_redis = Redis.new # default connection
```

Then, that Redis client is passed to the Subscription configuration:

```ruby
class MySchema < GraphQL::Schema
  use GraphQL::Pro::AblySubscriptions,
    redis: $graphql_subscriptions_redis,
    ably: Ably::Rest.new(key: ABLY_API_KEY)
end
```

That connection will be used for managing subscription state. All writes to Redis are prefixed with `graphql:sub:`.

## Execution configuration

During execution, GraphQL will assign a `subscription_id` to the `context` hash. The client will use that ID to listen for updates, so you must return the `subscription_id` in the response headers.

Return `result.context[:subscription_id]` as the `X-Subscription-ID` header. For example:

```ruby
result = MySchema.execute(...)
# For subscriptions, return the subscription_id as a header
if result.subscription?
  response.headers["X-Subscription-ID"] = result.context[:subscription_id]
end
render json: result
```

This way, the client can use that ID as a Ably channel.

For __CORS requests__, you need a special header so that clients can read the custom header:

```ruby
if result.subscription?
  response.headers["X-Subscription-ID"] = result.context[:subscription_id]
  # Required for CORS requests:
  response.headers["Access-Control-Expose-Headers"] = "X-Subscription-ID"
end
```

Read more here: ["Using CORS"](https://www.html5rocks.com/en/tutorials/cors/).

## Webhook configuration

Your server needs to receive webhooks from Ably when clients disconnect. This keeps your local subscription database in sync with Ably.

### Server
*Note: if you're setting up in a development environment you should follow the [Developing with webhooks](#Developing-with-webhooks) section first*

Mount the Rack app for handling webhooks from Ably. For example, on Rails:

```ruby
# config/routes.rb

# Include GraphQL::Pro's routing extensions:
using GraphQL::Pro::Routes

Rails.application.routes.draw do
  # ...
  # Handle webhooks for subscriptions:
  mount MySchema.ably_webhooks_client, at: "/ably_webhooks"
end
```

### Ably
1. Go to the Ably dashboard
2. Click on your application.
3. Select the "Reactor" tab
4. Click on the "+ New Reactor Rule" button
5. Click on the "Choose" button for "Reactor Event"
6. Click on the "Choose" button for "WebHooks"
7. Enter your url (including the webhooks path from above) in the URL field
8. Under "Source" select "Channel Lifecycle"
9. Under "Sign with key" select the API Key prefix that matches the prefix of the ABLY_API_KEY you provided.
10. Click "Create"

## Serializing Context

Since subscription state is stored in the database, then reloaded for pushing updates, you have to serialize and reload your query `context`.

By default, this is done with {{ "GraphQL::Subscriptions::Serialize" | api_doc }}'s `dump` and `load` methods, but you can provide custom implementations as well. To customize the serialization logic, create a subclass of `GraphQL::Pro::Subscriptions` and override `#dump_context(ctx)` and `#load_context(ctx_string)`:

```ruby
class CustomSubscriptions < GraphQL::Pro::AblySubscriptions
  def dump_context(ctx)
    context_hash = ctx.to_h
    # somehow convert this hash to a string, return the string
  end

  def load_context(ctx_string)
    # Given the string from the DB, create a new hash
    # to use as `context:`
  end
end
```

Then, use your _custom_ subscriptions class instead of the built-in one for your schema:

```ruby
class MySchema < GraphQL::Schema
  # Use custom subscriptions instead of GraphQL::Pro::AblySubscriptions
  # to get custom serialization logic
  use CustomSubscriptions, ...
end
```

That gives you fine-grained control of context reloading.

## Dashboard

You can monitor subscription state in the {% internal_link "GraphQL-Pro Dashboard", "/pro/dashboard" %}:

{{ "/subscriptions/redis_dashboard_1.png" | link_to_img:"Redis Subscription Dashboard" }}

{{ "/subscriptions/redis_dashboard_2.png" | link_to_img:"Redis Subscription Detail" }}

## Development Tips

#### Clear subscription data

At any time, you can reset your subscription database with the __"Reset"__ button in the {% internal_link "GraphQL-Pro Dashboard", "/pro/dashboard" %}, or in Ruby:

```ruby
# Wipe all subscription data from the DB:
MySchema.subscriptions.clear
```

#### Developing with webhooks

To receive webhooks in development, you can [use ngrok](https://www.ably.io/tutorials/webhook-chuck-norris). It gives you a public URL which you can setup with Ably, then any hooks delivered to that URL will be forwarded to your development environment.

## Client configuration

Install the [Ably JS client](https://github.com/ably/ably-js) then see docs for {% internal_link "Apollo Client", "/javascript_client/apollo_subscriptions" %}.
