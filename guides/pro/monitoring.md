---
title: GraphQL::Pro — Instrumentation For New Relic, Scout and Skylight
---

`GraphQL::Pro` includes instrumentation for [New Relic](https://newrelic.com/), [Scout](https://scoutapp.com), and [Skylight](skylight.io). All three platforms add:

- Tracking queries by name
- Tracking field resolution
- Observing database calls during resolution  

To add monitoring, provide one or more platform names to `monitoring(...)`:

```ruby
MySchema = GraphQL::Schema.define do
  # ...
  # Send query info to New Relic:
  monitoring(:new_relic)
  # Send info to Skylight and Scout:
  # monitoring(:skylight, :scout)
end
```

Supported platforms are `:new_relic`, `:scout` and `:skylight`.

## Previews

<div class="img-set">
{{ "/pro/newrelic_1.png" | img_set_member:"GraphQL New Relic Instrumentation 1" }}
{{ "/pro/newrelic_2.png" | img_set_member:"GraphQL New Relic Instrumentation 2" }}
{{ "/pro/scout_1.png" | img_set_member:"GraphQL Scout Instrumentation 1" }}
{{ "/pro/scout_2.png" | img_set_member:"GraphQL Scout Instrumentation 2" }}
{{ "/pro/skylight_1.png" | img_set_member:"GraphQL Skylight Instrumentation 1" }}
</div>
