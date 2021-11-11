---
layout: guide
search: true
section: Dataloader
title: Dataloader
desc: The Dataloader orchestrates Fibers and Sources
index: 2
---

{{ "GraphQL::Dataloader" | api_doc }} instances are created for each query (or multiplex) and they:

- Cache {% internal_link "Source", "/dataloader/sources" %} instances for the duration of GraphQL execution
- Run pending Fibers to resolve data requirements and continue GraphQL execution

During a query, you can access the dataloader instance with:

- {{ "GraphQL::Query::Context#dataloader" | api_doc }} (`context.dataloader`, anywhere that query context is available)
- {{ "GraphQL::Schema::Object#dataloader" | api_doc }} (`dataloader` inside a resolver method)
- {{ "GraphQL::Schema::Resolver#dataloader" | api_doc }} (`dataloader` inside `def resolve` of a Resolver, Mutation, or Subscription class.)
