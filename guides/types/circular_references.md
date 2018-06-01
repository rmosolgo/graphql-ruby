---
layout: guide
doc_stub: false
search: true
section: Types
title: Circular References, Lazy-Loading
desc: Use procs for lazy type resolution
index: 5
---

`.define { ... }` blocks are lazy-evaluated which handles most circular references. However, if you still have a problem, you can use a proc (`-> { ... }`) to lazy-load specific types.

For example, these are equivalent:

```ruby
# Access types directly:
# constant
field :team, TeamType
# local variable
field :stadium, stadium_type

# Access types dynamically:
# constant
field :team, -> { TeamType }
# custom logic
field :stadium, -> { LookupTypeForModel.lookup(Stadium) }
```
