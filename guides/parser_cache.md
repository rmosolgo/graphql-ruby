---
layout: guide
doc_stub: false
search: true
title: GraphQL Parser cache
section: Other
desc: How to make parsing GraphQL faster with caching
---

Parser caching may be optionally enabled by setting `config.graphql.parser_cache = true` in your Rails application. The cache may be manually built by assigning `GraphQL::Language::Parser.cache = GraphQL::Language::Cache.new("some_dir")`. This will create a directory (`tmp/cache/graphql` by default) that stores a cache of parsed files.

Much like [bootsnap](https://github.com/Shopify/bootsnap), the parser cache needs to be cleaned up manually. You will need to clear the cache directory for each new deployment of your application. Also note that the parser cache will grow as your schema is loaded, so the cache directory must be writable.
