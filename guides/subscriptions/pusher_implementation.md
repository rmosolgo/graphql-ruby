---
layout: guide
doc_stub: false
search: true
section: Subscriptions
title: Pusher Implementation
desc: GraphQL subscriptions over Pusher
index: 6
pro: true
---

[GraphQL Pro](http://graphql.pro) includes a subscription system based on [Redis](http://redis.io) and [Pusher](http://pusher.com) which works with any Ruby web framework.

After creating an app on Pusher and [configuring the Ruby gem](https://github.com/pusher/pusher-http-ruby#global), you can hook it up to your GraphQL schema.

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
- __Pusher__ sends updates to subscribed clients

So, the lifecycle goes like this:

- A `subscription` query is sent by HTTP Post to your server (just like a `query` or `mutation`)
- The response contains a Pusher channel ID (as an HTTP header) which the client may subscribe to
- The client opens that Pusher channel
- When the server triggers updates, they're delivered over the Pusher channel
- When the client unsubscribes, the server receives a webhook and responds by removing its subscription data

Here's another look:

```
1. Subscription is created in your app

          HTTP POST
        .---------->   write to Redis
      📱            ⚙️ -----> 💾
        <---------'
        X-Subscription-ID: 1234


2. Client opens a connection to Pusher

          websocket
      📱 <---------> ☁️


3. The app sends updates via Pusher

      ⚙️ ---------> ☁️ ------> 📱
        POST           update
      (via gem)   (via websocket)


4. When the client unsubscribes, Pusher notifies the app

          webhook
      ⚙️ <-------- ☁️  (disconnect) 📱
```


By using this configuration, you can use GraphQL subscriptions without hosting a push server yourself!

## Database setup

Subscriptions require a _persistent_ Redis database, configured with:

```sh
maxmemory-policy noeviction
# optional, more durable persistence:
appendonly yes
```

Otherwise, Redis will drop data that doesn't fit in memory (read more in ["Redis persistence"](https://redis.io/topics/persistence)).

If you're already using Redis in your application, see ["Storing Data in Redis"](http://www.mikeperham.com/2015/09/24/storing-data-with-redis/) for options to isolate data and tune your configuration.

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
  use GraphQL::Pro::Subscriptions, redis: $graphql_subscriptions_redis
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

This way, the client can use that ID as a Pusher channel.

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

Your server needs to receive webhooks from Pusher when clients disconnect. This keeps your local subscription database in sync with Pusher.

In the Pusher web UI, Add a webhook for "Channel existence"

{{ "/subscriptions/pusher_webhook_configuration.png" | link_to_img:"Pusher Webhook Configuration" }}

Then, mount the Rack app for handling webhooks from Pusher. For example, on Rails:

```ruby
# config/routes.rb

# Include GraphQL::Pro's routing extensions:
using GraphQL::Pro::Routes

Rails.application.routes.draw do
  # ...
  # Handle Pusher webhooks for subscriptions:
  mount MySchema.pusher_webhooks_client, at: "/pusher_webhooks"
end
```

This way, we'll be kept up-to-date with Pusher's unsubscribe events.

## Authorization

To ensure the privacy of subscription updates, you should use a [private channel](https://pusher.com/docs/client_api_guide/client_private_channels) for transport.

To use a private channel, add a `channel_prefix:` key to your query context:

```ruby
MySchema.execute(
  query_string,
  context: {
    # If this query is a subscription, use this prefix for the Pusher channel:
    channel_prefix: "private-user-#{current_user.id}-",
    # ...
  },
  # ...
)
```

That prefix will be applied to GraphQL-related Pusher channel names. (The prefix should begin with `private-`, as required by Pusher.)

Then, in your [auth endpoint](https://pusher.com/docs/authenticating_users#implementing_private_endpoints), you can assert that the logged-in user matches the channel name:

```ruby
if params[:channel_name].start_with?("private-user-#{current_user.id}-")
  # success, render the auth token
else
  # failure, render unauthorized
end
```

## Serializing Context

Since subscription state is stored in the database, then reloaded for pushing updates, you have to serialize and reload your query `context`.

By default, this is done with {{ "GraphQL::Subscriptions::Serialize" | api_doc }}'s `dump` and `load` methods, but you can provide custom implementations as well. To customize the serialization logic, create a subclass of `GraphQL::Pro::Subscriptions` and override `#dump_context(ctx)` and `#load_context(ctx_string)`:

```ruby
class CustomSubscriptions < GraphQL::Pro::Subscriptions
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
  # Use custom subscriptions instead of GraphQL::Pro::Subscriptions
  # to get custom serialization logic
  use CustomSubscriptions, redis: $redis
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

#### Developing with Pusher webhooks

To receive Pusher's webhooks in development, Pusher [suggests using ngrok](https://support.pusher.com/hc/en-us/articles/203112227-Developing-against-and-testing-WebHooks). It gives you a public URL which you can setup with Pusher, then any hooks delivered to that URL will be forwarded to your development environment.

## Client configuration

Install the [Pusher JS client](https://github.com/pusher/pusher-js) then see docs for {% internal_link "Apollo Client", "/javascript_client/apollo_subscriptions" %} or {% internal_link "Relay Modern", "/javascript_client/relay_subscriptions" %}.
