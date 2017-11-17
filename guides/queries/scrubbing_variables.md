---
title: Scrubbing Variables
layout: guide
search: true
section: Queries
desc: Hide certain variable values for logging
index: 13
---

You can scrub query variables so that sensitive values aren't written to logs.

To specify scrubbing settings, use `scrub` in your schema definition:

```ruby
MySchema = GraphQL::Schema.define do
  # ...
  scrub(
    whitelist: [:id, :name],        # only show these variables
    # OR:
    blacklist: [:password, :token], # always _hide_ these variables
    # optionally:
    mutations: false, # always hide _all_ variables for mutation operations
  )
end
```

Then, in your logging, use {{ "Query#scrubbed_variables" | api_doc }}, which will apply your scrubbing settings:

```ruby
# For example, in query instrumentation:
def before_query(query)
  Rails.logger.info(query.scrubbed_variables)
end
```
