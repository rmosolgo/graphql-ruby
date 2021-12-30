---
name: Bug report
about: Create a report to help us improve graphql-ruby
title: ''
labels: ''
assignees: ''

---

**Describe the bug**

A clear and concise description of what the bug is.

**Versions**

`graphql` version:
`rails` (or other framework):
other applicable versions (`graphql-batch`, etc)

**GraphQL schema**

Include relevant types and fields (in Ruby is best, in GraphQL IDL is ok). Any custom extensions, etc?

```ruby
class Product < GraphQL::Schema::Object
  field :id, ID, hash_key: :id
  # …
end

class ApplicationSchema < GraphQL::Schema
  query QueryType
  # …
end
```

**GraphQL query**

Example GraphQL query and response (if query execution is involved)

```graphql
query {
  products { id title }
}
```

```json
{
  "data": {
    "products": […]
  }
}
```

**Steps to reproduce**

Steps to reproduce the behavior

**Expected behavior**

A clear and concise description of what you expected to happen.

**Actual behavior**

What specifically went wrong?

Place full backtrace here (if a Ruby exception is involved):

<details>
<summary>Click to view exception backtrace</summary>

```
Something went wrong
2.6.0/gems/graphql-1.9.17/lib/graphql/subscriptions/instrumentation.rb:34:in `after_query'
… don't hesitate to include all the rows here: they will be collapsed
```

</details>

**Additional context**

Add any other context about the problem here.

With these details, we can efficiently hunt down the bug!
