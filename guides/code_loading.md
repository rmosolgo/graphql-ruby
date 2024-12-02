---
layout: guide
doc_stub: false
search: true
title: Code Loading
section: Other
desc: Read this before deploying GraphQL to production.
---

## Autoloading and Eager Loading

GraphQL Ruby is autoloaded, which means most code won't be loaded until it is referenced. This is optimal for development and test environments where you want to boot your application as fast as possible. However, this is not optimal for production enviromnets.

Production environments typically include multiple workers, and need to load an application upfront as much as possible. This ensures requests are as fast as possible at the cost of increased boot time, and forked processes don't need to load additional code. Unfortunately, there is no approach to eager code loading that is accepted by all web application frameworks.

- For Rails applications, a Railtie is included that automatically eager-loads the GraphQL Ruby library for you. No action is required by the developer to opt into this behaviour.

- For Sinatra applications, please put `configure(:production) { GraphQL.eager_load! }` in your application file.

- For Hanami applications, please put `environment(:production) { GraphQL.eager_load! }` in your application file.

- Other frameworks need to manually call `GraphQL.eager_load!` when their application is booting in production mode. If this is not done properly, GraphQL Ruby will log an warning.
